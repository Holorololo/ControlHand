import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../config/performance_config.dart';
import '../data/models/auto_state.dart';
import '../data/repositories/backend_api_repository.dart';

enum SocketConnectionStatus { disconnected, connecting, connected }

class AutoStatePollingService extends GetxService {
  final Rx<SocketConnectionStatus> status =
      SocketConnectionStatus.disconnected.obs;
  final Rxn<AutoState> latestState = Rxn<AutoState>();
  final RxString errorMessage = ''.obs;
  final Rxn<DateTime> lastPacketAt = Rxn<DateTime>();

  http.Client? _client;
  BackendApiRepository? _backendApiRepository;
  Timer? _pollTimer;
  Timer? _reconnectTimer;
  bool _manualDisconnect = false;
  bool _pollInProgress = false;
  bool _disposed = false;
  bool _previewStreamingEnabled = true;
  Uint8List? _lastPreviewBytes;
  int? _lastPreviewWidth;
  int? _lastPreviewHeight;
  int? _lastPreviewVersion;
  DateTime? _lastPreviewRefreshAt;
  int _consecutiveFailureCount = 0;
  int _successfulPollCount = 0;
  int _failedPollCount = 0;

  String _scheme = 'http';
  String _host = '127.0.0.1';
  int _port = 5000;

  String get host => _host;
  int get port => _port;
  String get baseUrl => '$_scheme://$_host:$_port';
  bool get previewStreamingEnabled => _previewStreamingEnabled;
  Duration get _pollInterval => _previewStreamingEnabled
      ? const Duration(milliseconds: PerformanceConfig.pollingIntervalMs)
      : const Duration(
          milliseconds: PerformanceConfig.backgroundPollingIntervalMs,
        );

  Future<void> connect({String? host, int? port}) async {
    final endpoint = _normalizeEndpoint(host: host, port: port);
    _scheme = endpoint.scheme;
    _host = endpoint.host;
    _port = endpoint.port;
    _manualDisconnect = false;
    errorMessage.value = '';

    await _closeConnection();
    status.value = SocketConnectionStatus.connecting;
    _client = http.Client();
    _backendApiRepository = BackendApiRepository(
      client: _client!,
      baseUrl: baseUrl,
    );

    try {
      await _backendApiRepository!.getHealth();

      _consecutiveFailureCount = 0;
      status.value = SocketConnectionStatus.connected;
      await _pollBackend();
      _startPolling();
    } catch (error) {
      _handleConnectionFailure(error);
    }
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    errorMessage.value = '';
    await _closeConnection();
    status.value = SocketConnectionStatus.disconnected;
  }

  Future<void> _pollBackend() async {
    if (_manualDisconnect || _pollInProgress || _backendApiRepository == null) {
      return;
    }

    _pollInProgress = true;
    final stopwatch = Stopwatch()..start();

    try {
      final snapshot = await _backendApiRepository!.getState();
      final previewVersion = snapshot.cameraPreviewVersion;
      final previewAvailable = snapshot.cameraPreviewAvailable;
      if (_previewStreamingEnabled) {
        _lastPreviewWidth = snapshot.cameraPreviewWidth;
        _lastPreviewHeight = snapshot.cameraPreviewHeight;

        if (previewAvailable && _shouldRefreshPreview(previewVersion)) {
          await _refreshPreview(previewVersion);
        } else if (!previewAvailable) {
          _clearPreviewCache();
        }
      } else {
        _clearPreviewCache();
      }

      final state = AutoState.fromSnapshotDto(
        snapshot,
        previewBytes: _lastPreviewBytes,
        previewWidth: _lastPreviewWidth,
        previewHeight: _lastPreviewHeight,
      );

      _consecutiveFailureCount = 0;
      _successfulPollCount++;
      if (_hasMeaningfulStateChanged(latestState.value, state)) {
        latestState.value = state;
      }
      lastPacketAt.value = state.timestamp;
      errorMessage.value = '';
      status.value = SocketConnectionStatus.connected;
      _maybeLogPollingMetrics(stopwatch.elapsed);
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
    if (_backendApiRepository == null) {
      return;
    }

    _lastPreviewRefreshAt = DateTime.now();
    final previewBytes = await _backendApiRepository!.getPreview(
      version: previewVersion,
    );

    if (previewBytes != null && previewBytes.isNotEmpty) {
      _lastPreviewBytes = previewBytes;
      _lastPreviewVersion = previewVersion;
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
    errorMessage.value =
        'Se perdio la conexion con el backend Flask. ${error.toString()}';
    status.value = SocketConnectionStatus.disconnected;
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
    errorMessage.value = 'No se pudo conectar a $baseUrl. ${error.toString()}';
    status.value = SocketConnectionStatus.disconnected;
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
  }

  void _clearPreviewCache() {
    _lastPreviewBytes = null;
    _lastPreviewWidth = null;
    _lastPreviewHeight = null;
    _lastPreviewVersion = null;
    _lastPreviewRefreshAt = null;
  }

  bool _hasMeaningfulStateChanged(AutoState? previous, AutoState next) {
    if (previous == null) {
      return true;
    }

    return previous.handDetected != next.handDetected ||
        previous.handState != next.handState ||
        previous.fingersUp != next.fingersUp ||
        previous.carMoving != next.carMoving ||
        previous.carX != next.carX ||
        previous.carY != next.carY ||
        previous.speed != next.speed ||
        previous.backendReady != next.backendReady ||
        previous.backendMessage != next.backendMessage ||
        previous.backendLastError != next.backendLastError ||
        !identical(previous.previewBytes, next.previewBytes) ||
        previous.hasCameraPreview != next.hasCameraPreview ||
        previous.cameraFrameWidth != next.cameraFrameWidth ||
        previous.cameraFrameHeight != next.cameraFrameHeight;
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
