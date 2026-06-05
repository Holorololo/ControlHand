import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../config/performance_config.dart';
import '../data/dtos/backend_snapshot_dto.dart';
import '../data/models/auto_state.dart';
import '../data/repositories/backend_api_repository.dart';

enum SocketConnectionStatus { disconnected, connecting, connected }

class AutoStatePollingService extends GetxService {
  AutoStatePollingService({
    http.Client Function()? clientFactory,
    BackendApiRepository Function(http.Client client, String baseUrl)?
    repositoryFactory,
  }) : _clientFactory = clientFactory,
       _repositoryFactory = repositoryFactory;

  final Rx<SocketConnectionStatus> status =
      SocketConnectionStatus.disconnected.obs;
  final Rxn<AutoState> latestState = Rxn<AutoState>();
  final RxString errorMessage = ''.obs;
  final Rxn<DateTime> lastPacketAt = Rxn<DateTime>();

  final http.Client Function()? _clientFactory;
  final BackendApiRepository Function(http.Client client, String baseUrl)?
  _repositoryFactory;

  http.Client? _client;
  BackendApiRepository? _backendApiRepository;
  Timer? _pollTimer;
  Timer? _reconnectTimer;
  bool _manualDisconnect = false;
  bool _connectInProgress = false;
  bool _pollInProgress = false;
  bool _previewFetchInProgress = false;
  bool _disposed = false;
  bool _previewStreamingEnabled = true;
  Uint8List? _lastPreviewBytes;
  int? _lastPreviewWidth;
  int? _lastPreviewHeight;
  int? _lastPreviewVersion;
  DateTime? _lastPreviewRefreshAt;
  int _previewRefreshCount = 0;
  int _consecutiveFailureCount = 0;
  int _successfulPollCount = 0;
  int _failedPollCount = 0;
  int _lastPollMs = 0;
  int _lastStateFetchMs = 0;
  int _lastPreviewFetchMs = 0;
  int _stateLogCount = 0;
  DateTime? _lastSuccessfulPollAt;
  String _lastPreviewError = '';
  String? _lastLoggedPayload;

  String _scheme = 'http';
  String _host = '127.0.0.1';
  int _port = 5000;

  String get host => _host;
  int get port => _port;
  String get baseUrl => '$_scheme://$_host:$_port';
  bool get previewStreamingEnabled => _previewStreamingEnabled;
  int get lastPollMs => _lastPollMs;
  int get lastStateFetchMs => _lastStateFetchMs;
  int get lastPreviewFetchMs => _lastPreviewFetchMs;
  DateTime? get lastSuccessfulPollAt => _lastSuccessfulPollAt;
  int get consecutiveFailureCount => _consecutiveFailureCount;
  bool get pollInProgress => _pollInProgress;
  bool get previewFetchInProgress => _previewFetchInProgress;
  String get lastPreviewError => _lastPreviewError;
  String get metricsSummary => [
    'backend_polling:',
    '  status: ${status.value.name}',
    '  preview_streaming: $previewStreamingEnabled',
    '  poll_in_progress: $pollInProgress',
    '  preview_fetch_in_progress: $previewFetchInProgress',
    '  consecutive_failures: $consecutiveFailureCount',
    '  last_poll_ms: $lastPollMs',
    '  last_state_fetch_ms: $lastStateFetchMs',
    '  last_preview_fetch_ms: $lastPreviewFetchMs',
    '  last_successful_poll_at: ${_formatDateTime(lastSuccessfulPollAt)}',
    '  last_preview_error: ${lastPreviewError.isEmpty ? 'none' : lastPreviewError}',
  ].join('\n');
  Duration get _pollInterval => _previewStreamingEnabled
      ? const Duration(milliseconds: PerformanceConfig.pollingIntervalMs)
      : const Duration(
          milliseconds: PerformanceConfig.backgroundPollingIntervalMs,
        );

  Future<void> connect({String? host, int? port}) async {
    if (_connectInProgress || _disposed) {
      return;
    }

    _connectInProgress = true;
    final endpoint = _normalizeEndpoint(host: host, port: port);
    _scheme = endpoint.scheme;
    _host = endpoint.host;
    _port = endpoint.port;
    _manualDisconnect = false;
    _setRxIfChanged<String>(errorMessage, '');
    _lastPreviewError = '';
    _lastPollMs = 0;
    _lastStateFetchMs = 0;
    _lastPreviewFetchMs = 0;

    try {
      await _closeConnection();
      _setRxIfChanged<SocketConnectionStatus>(
        status,
        SocketConnectionStatus.connecting,
      );
      _client = (_clientFactory ?? http.Client.new)();
      _backendApiRepository =
          _repositoryFactory?.call(_client!, baseUrl) ??
          BackendApiRepository(client: _client!, baseUrl: baseUrl);

      await _backendApiRepository!.getHealth();

      _consecutiveFailureCount = 0;
      _setRxIfChanged<SocketConnectionStatus>(
        status,
        SocketConnectionStatus.connected,
      );
      await _pollBackend();
      _startPolling();
    } catch (error) {
      _handleConnectionFailure(error);
    } finally {
      _connectInProgress = false;
    }
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _setRxIfChanged<String>(errorMessage, '');
    await _closeConnection();
    _setRxIfChanged<SocketConnectionStatus>(
      status,
      SocketConnectionStatus.disconnected,
    );
  }

  Future<void> _pollBackend() async {
    if (_manualDisconnect || _pollInProgress || _backendApiRepository == null) {
      return;
    }

    _pollInProgress = true;
    final stopwatch = Stopwatch()..start();

    try {
      final stateStopwatch = Stopwatch()..start();
      final snapshot = await _backendApiRepository!.getState();
      _lastStateFetchMs = stateStopwatch.elapsedMilliseconds;
      _publishSnapshotState(snapshot);

      _consecutiveFailureCount = 0;
      _successfulPollCount++;
      _lastSuccessfulPollAt = DateTime.now();
      _setRxIfChanged<String>(errorMessage, '');
      _setRxIfChanged<SocketConnectionStatus>(
        status,
        SocketConnectionStatus.connected,
      );
      _lastPollMs = stopwatch.elapsedMilliseconds;
      _maybeLogPollingMetrics(stopwatch.elapsed);

      final previewVersion = snapshot.cameraPreviewVersion;
      final previewAvailable = snapshot.cameraPreviewAvailable;
      if (_previewStreamingEnabled &&
          previewAvailable &&
          _shouldRefreshPreview(previewVersion)) {
        unawaited(_refreshPreview(previewVersion));
      }
    } catch (error) {
      _handlePollingFailure(error);
    } finally {
      _pollInProgress = false;
    }
  }

  bool _shouldRefreshPreview(int? previewVersion) {
    if (!_previewStreamingEnabled) {
      return false;
    }

    if (_previewFetchInProgress) {
      return false;
    }

    final versionChanged =
        previewVersion == null ||
        previewVersion != _lastPreviewVersion ||
        _lastPreviewBytes == null;
    if (!versionChanged) {
      return false;
    }

    final lastRefreshAt = _lastPreviewRefreshAt;
    if (lastRefreshAt == null) {
      return true;
    }

    return DateTime.now().difference(lastRefreshAt) >=
        const Duration(
          milliseconds: PerformanceConfig.previewRefreshIntervalMs,
        );
  }

  Future<void> _refreshPreview(int? previewVersion) async {
    if (_backendApiRepository == null || _previewFetchInProgress) {
      return;
    }

    _previewFetchInProgress = true;
    _lastPreviewRefreshAt = DateTime.now();
    final stopwatch = Stopwatch()..start();
    try {
      final previewBytes = await _backendApiRepository!.getPreview(
        version: previewVersion,
      );
      _lastPreviewFetchMs = stopwatch.elapsedMilliseconds;

      if (previewBytes != null && previewBytes.isNotEmpty) {
        _lastPreviewBytes = previewBytes;
        _lastPreviewVersion = previewVersion;
        _previewRefreshCount++;
        _lastPreviewError = '';
        _publishPreviewRefresh();
        _logPreviewRefresh(previewVersion);
      }
    } on TimeoutException catch (error) {
      _lastPreviewFetchMs = stopwatch.elapsedMilliseconds;
      _lastPreviewError = error.message ?? 'Timeout al descargar preview.';
      _logPreviewTimeout(error);
    } catch (error) {
      _lastPreviewFetchMs = stopwatch.elapsedMilliseconds;
      _lastPreviewError = error.toString();
      _logPreviewFailure(error);
    } finally {
      _previewFetchInProgress = false;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(_pollBackend());
    });
  }

  void setPreviewStreamingEnabled(bool enabled) {
    if (_previewStreamingEnabled == enabled) {
      return;
    }

    _previewStreamingEnabled = enabled;
    if (!enabled) {
      _clearPreviewCache();
      final currentState = latestState.value;
      if (currentState != null) {
        latestState.value = currentState.copyWith(clearPreview: true);
      }
    }

    if (status.value == SocketConnectionStatus.connected) {
      _startPolling();
      unawaited(_pollBackend());
    }
  }

  void _handlePollingFailure(Object error) {
    _failedPollCount++;
    _consecutiveFailureCount++;
    _setRxIfChanged<String>(
      errorMessage,
      'Se perdio la conexion con el backend Flask. '
      '${_normalizeBackendError(error)}',
    );
    _setRxIfChanged<SocketConnectionStatus>(
      status,
      SocketConnectionStatus.disconnected,
    );
    if (kDebugMode) {
      debugPrint(
        'AutoStatePollingService -> poll failed '
        '(count=$_failedPollCount, streak=$_consecutiveFailureCount): $error',
      );
    }
    _scheduleReconnect();
  }

  void _handleConnectionFailure(Object error) {
    _failedPollCount++;
    _consecutiveFailureCount++;
    _setRxIfChanged<String>(
      errorMessage,
      'No se pudo conectar a $baseUrl. ${_normalizeBackendError(error)}',
    );
    _setRxIfChanged<SocketConnectionStatus>(
      status,
      SocketConnectionStatus.disconnected,
    );
    if (kDebugMode) {
      debugPrint(
        'AutoStatePollingService -> connect failed '
        '(count=$_failedPollCount, streak=$_consecutiveFailureCount): $error',
      );
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect || _disposed) {
      return;
    }

    _pollTimer?.cancel();
    _reconnectTimer?.cancel();
    final exponent = (_consecutiveFailureCount - 1).clamp(0, 3);
    final backoffFactor = 1 << exponent;
    final reconnectDelayMs =
        PerformanceConfig.reconnectBaseDelayMs * backoffFactor;
    final cappedDelayMs =
        reconnectDelayMs > PerformanceConfig.reconnectMaxDelayMs
        ? PerformanceConfig.reconnectMaxDelayMs
        : reconnectDelayMs;
    _reconnectTimer = Timer(Duration(milliseconds: cappedDelayMs), () {
      if (status.value == SocketConnectionStatus.disconnected &&
          !_manualDisconnect) {
        unawaited(connect());
      }
    });
  }

  Future<void> _closeConnection() async {
    _pollTimer?.cancel();
    _reconnectTimer?.cancel();
    _client?.close();
    _client = null;
    _backendApiRepository = null;
    _pollInProgress = false;
    _previewFetchInProgress = false;
  }

  void _clearPreviewCache() {
    _lastPreviewBytes = null;
    _lastPreviewWidth = null;
    _lastPreviewHeight = null;
    _lastPreviewVersion = null;
    _lastPreviewRefreshAt = null;
    _previewRefreshCount = 0;
  }

  bool _hasMeaningfulStateChanged(AutoState? previous, AutoState next) {
    if (previous == null) {
      return true;
    }

    return previous.handDetected != next.handDetected ||
        previous.normalizedHandStatus != next.normalizedHandStatus ||
        previous.handState != next.handState ||
        previous.command != next.command ||
        previous.payload != next.payload ||
        previous.fingersUp != next.fingersUp ||
        previous.carMoving != next.carMoving ||
        previous.carX != next.carX ||
        previous.carY != next.carY ||
        previous.speed != next.speed ||
        previous.backendReady != next.backendReady ||
        previous.backendMessage != next.backendMessage ||
        previous.backendLastError != next.backendLastError ||
        previous.previewVersion != next.previewVersion ||
        !identical(previous.previewBytes, next.previewBytes) ||
        previous.hasCameraPreview != next.hasCameraPreview ||
        previous.cameraFrameWidth != next.cameraFrameWidth ||
        previous.cameraFrameHeight != next.cameraFrameHeight ||
        previous.handLabel != next.handLabel ||
        previous.rawFingerCount != next.rawFingerCount ||
        previous.stableFingerCount != next.stableFingerCount ||
        previous.rawHandStatus != next.rawHandStatus ||
        previous.rawCommand != next.rawCommand ||
        previous.rawPayload != next.rawPayload ||
        !_sameFingerMap(previous.rawFingers, next.rawFingers) ||
        previous.stabilityFramesRequired != next.stabilityFramesRequired ||
        previous.stabilityMatchCount != next.stabilityMatchCount;
  }

  bool _sameFingerMap(Map<String, bool> previous, Map<String, bool> next) {
    if (identical(previous, next)) {
      return true;
    }

    if (previous.length != next.length) {
      return false;
    }

    for (final entry in previous.entries) {
      if (next[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }

  void _maybeLogPollingMetrics(Duration elapsed) {
    if (!kDebugMode) {
      return;
    }

    if (_successfulPollCount % PerformanceConfig.performanceLogSampleSize !=
        0) {
      return;
    }

    debugPrint(
      'AutoStatePollingService -> polls=$_successfulPollCount '
      'last=${elapsed.inMilliseconds}ms '
      'preview=${_previewStreamingEnabled ? 'on' : 'off'} '
      'failures=$_failedPollCount',
    );
  }

  void _logPreviewRefresh(int? previewVersion) {
    if (!kDebugMode) {
      return;
    }

    final count = _previewRefreshCount;
    if (count != 1 && count % PerformanceConfig.performanceLogSampleSize != 0) {
      return;
    }

    debugPrint(
      'AutoStatePollingService -> preview updated '
      '(count=$count, version=${previewVersion ?? -1})',
    );
  }

  void _logPreviewTimeout(TimeoutException error) {
    if (!kDebugMode) {
      return;
    }

    debugPrint(
      'AutoStatePollingService -> preview timeout: '
      '${error.message ?? 'sin mensaje'}',
    );
  }

  void _logPreviewFailure(Object error) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('AutoStatePollingService -> preview refresh failed: $error');
  }

  void _logStateUpdate(AutoState state) {
    if (!kDebugMode) {
      return;
    }

    _stateLogCount++;
    final shouldLog =
        _stateLogCount == 1 ||
        _stateLogCount % PerformanceConfig.performanceLogSampleSize == 0 ||
        state.payload != _lastLoggedPayload;
    if (!shouldLog) {
      return;
    }

    _lastLoggedPayload = state.payload;
    debugPrint(
      'AutoStatePollingService -> state '
      'label=${state.handLabel.isEmpty ? 'n/a' : state.handLabel} '
      'hand=${state.normalizedHandStatus} '
      'raw_fingers=${state.rawFingers} '
      'raw_count=${state.rawFingerCount} '
      'stable_count=${state.stableFingerCount} '
      'command=${state.command} '
      'payload=${state.payload}',
    );
  }

  String _normalizeBackendError(Object error) {
    var message = error.toString().trim();
    const prefixes = <String>['Exception:', 'Bad state:'];

    for (final prefix in prefixes) {
      if (message.startsWith(prefix)) {
        message = message.substring(prefix.length).trim();
      }
    }

    if (message.isEmpty) {
      return 'Error inesperado al consultar el backend.';
    }

    return message;
  }

  void _setRxIfChanged<T>(dynamic rx, T value) {
    if (rx.value == value) {
      return;
    }

    rx.value = value;
  }

  void _publishSnapshotState(BackendSnapshotDto snapshot) {
    if (_previewStreamingEnabled) {
      _lastPreviewWidth = snapshot.cameraPreviewWidth;
      _lastPreviewHeight = snapshot.cameraPreviewHeight;
      if (!snapshot.cameraPreviewAvailable) {
        _clearPreviewCache();
      }
    } else {
      _clearPreviewCache();
    }

    final hasCachedPreview =
        _lastPreviewBytes != null && _lastPreviewBytes!.isNotEmpty;
    final state = AutoState.fromSnapshotDto(
      snapshot,
      previewBytes: _lastPreviewBytes,
      previewVersion: hasCachedPreview ? _lastPreviewVersion : null,
      previewWidth: hasCachedPreview ? _lastPreviewWidth : null,
      previewHeight: hasCachedPreview ? _lastPreviewHeight : null,
    );

    if (_hasMeaningfulStateChanged(latestState.value, state)) {
      latestState.value = state;
      _logStateUpdate(state);
    }
    lastPacketAt.value = state.timestamp;
  }

  void _publishPreviewRefresh() {
    final currentState = latestState.value;
    if (currentState == null) {
      return;
    }

    final refreshedState = currentState.copyWith(
      previewBytes: _lastPreviewBytes,
      previewVersion: _lastPreviewVersion,
      cameraFrameWidth: _lastPreviewWidth,
      cameraFrameHeight: _lastPreviewHeight,
    );

    if (_hasMeaningfulStateChanged(currentState, refreshedState)) {
      latestState.value = refreshedState;
    }
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'n/a';
    }

    return value.toIso8601String();
  }

  _Endpoint _normalizeEndpoint({String? host, int? port}) {
    var scheme = _scheme;
    var normalizedHost = (host ?? _host).trim();
    var normalizedPort = port ?? _port;

    if (normalizedHost.contains('://')) {
      final uri = Uri.tryParse(normalizedHost);
      if (uri != null) {
        if (uri.scheme.isNotEmpty) {
          scheme = uri.scheme;
        }
        if (uri.host.isNotEmpty) {
          normalizedHost = uri.host;
        }
        if (uri.hasPort) {
          normalizedPort = uri.port;
        }
      }
    }

    normalizedHost = normalizedHost.replaceFirst(RegExp(r'^https?://'), '');
    normalizedHost = normalizedHost.replaceAll('/', '');

    return _Endpoint(
      scheme: scheme,
      host: normalizedHost,
      port: normalizedPort,
    );
  }

  @override
  void onClose() {
    _disposed = true;
    _pollTimer?.cancel();
    _reconnectTimer?.cancel();
    _client?.close();
    super.onClose();
  }
}

class _Endpoint {
  const _Endpoint({
    required this.scheme,
    required this.host,
    required this.port,
  });

  final String scheme;
  final String host;
  final int port;
}
