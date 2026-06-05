import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../config/performance_config.dart';
import '../data/repositories/backend_api_repository.dart';

enum MobileCameraRelayStatus {
  unsupported,
  idle,
  initializing,
  ready,
  streaming,
  permissionDenied,
  failed,
}

class MobileCameraRelayService extends GetxService with WidgetsBindingObserver {
  final Rx<MobileCameraRelayStatus> status =
      MobileCameraRelayStatus.unsupported.obs;
  final RxString infoMessage = ''.obs;
  final Rxn<DateTime> lastFrameSentAt = Rxn<DateTime>();

  final Duration _frameInterval = const Duration(
    milliseconds: PerformanceConfig.frameSendIntervalMs,
  );

  CameraController? _controller;
  CameraDescription? _selectedCamera;
  http.Client? _client;
  BackendApiRepository? _backendApiRepository;
  String? _baseUrl;
  bool _streamRequested = false;
  bool _uploadInProgress = false;
  int _uploadedFrameCount = 0;
  int _failedFrameCount = 0;
  int _droppedBusyFrameCount = 0;
  int _intervalSkippedFrameCount = 0;
  int _uploadAttemptCount = 0;

  bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  CameraController? get controller => _controller;
  bool get hasPreview =>
      _controller != null && _controller!.value.isInitialized;
  bool get isStreaming => status.value == MobileCameraRelayStatus.streaming;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    if (supported) {
      _setStatusIfChanged(MobileCameraRelayStatus.idle);
      _setInfoMessageIfChanged(
        'La camara del celular se activara cuando te conectes al backend.',
      );
    } else {
      _setStatusIfChanged(MobileCameraRelayStatus.unsupported);
      _setInfoMessageIfChanged(
        'La camara del celular solo se usa en Android o iPhone.',
      );
    }
  }

  Future<void> preparePreview() async {
    if (!supported) {
      return;
    }

    await _ensureCameraReady();
  }

  Future<void> startRelay({required String host, required int port}) async {
    if (!supported) {
      _setStatusIfChanged(MobileCameraRelayStatus.unsupported);
      return;
    }

    _streamRequested = true;
    _baseUrl = _normalizeBaseUrl(host, port);
    _client ??= http.Client();
    _backendApiRepository = BackendApiRepository(
      client: _client!,
      baseUrl: _baseUrl!,
    );
    _uploadedFrameCount = 0;
    _failedFrameCount = 0;
    _droppedBusyFrameCount = 0;
    _intervalSkippedFrameCount = 0;
    _uploadAttemptCount = 0;
    lastFrameSentAt.value = null;

    await _ensureCameraReady();

    final cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (!cameraController.value.isStreamingImages) {
      await cameraController.startImageStream(_handleCameraImage);
    }

    _setStatusIfChanged(MobileCameraRelayStatus.streaming);
    _setInfoMessageIfChanged(
      'Camara del celular activa. Enviando frames a $_baseUrl.',
    );
  }

  Future<void> stopRelay({bool disposeCamera = false}) async {
    _streamRequested = false;
    _baseUrl = null;
    _backendApiRepository = null;
    _uploadInProgress = false;

    final cameraController = _controller;
    if (cameraController != null && cameraController.value.isStreamingImages) {
      await cameraController.stopImageStream();
    }

    if (disposeCamera) {
      await _disposeCameraController();
      _setStatusIfChanged(
        supported
            ? MobileCameraRelayStatus.idle
            : MobileCameraRelayStatus.unsupported,
      );
      return;
    }

    if (hasPreview) {
      _setStatusIfChanged(MobileCameraRelayStatus.ready);
      _setInfoMessageIfChanged('Camara del celular lista, sin enviar frames.');
    } else if (supported) {
      _setStatusIfChanged(MobileCameraRelayStatus.idle);
      _setInfoMessageIfChanged(
        'La camara del celular se activara cuando te conectes al backend.',
      );
    }
  }

  Future<void> _ensureCameraReady() async {
    if (hasPreview) {
      if (status.value == MobileCameraRelayStatus.initializing) {
        status.value = MobileCameraRelayStatus.ready;
      }
      return;
    }

    _setStatusIfChanged(MobileCameraRelayStatus.initializing);
    _setInfoMessageIfChanged('Abriendo la camara del celular...');

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _setStatusIfChanged(MobileCameraRelayStatus.failed);
        _setInfoMessageIfChanged('No se encontro una camara disponible.');
        return;
      }

      await _disposeCameraController();

      final selectedCamera = _selectedCamera == null
          ? _pickPreferredCamera(cameras)
          : cameras.firstWhere(
              (camera) => camera.name == _selectedCamera!.name,
              orElse: () => _pickPreferredCamera(cameras),
            );
      final controller = CameraController(
        selectedCamera,
        PerformanceConfig.mobileCameraResolutionPreset,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );

      await controller.initialize();
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {
        // Algunos dispositivos no permiten ajustar el flash en este modo.
      }

      _selectedCamera = selectedCamera;
      _controller = controller;
      _setStatusIfChanged(MobileCameraRelayStatus.ready);
      _setInfoMessageIfChanged('Camara del celular lista.');
    } on CameraException catch (error) {
      if (error.code == 'CameraAccessDenied' ||
          error.code == 'CameraAccessDeniedWithoutPrompt' ||
          error.code == 'CameraAccessRestricted') {
        _setStatusIfChanged(MobileCameraRelayStatus.permissionDenied);
        _setInfoMessageIfChanged(
          'No se concedio acceso a la camara del celular.',
        );
      } else {
        _setStatusIfChanged(MobileCameraRelayStatus.failed);
        _setInfoMessageIfChanged(
          'No se pudo inicializar la camara. ${error.code}',
        );
      }
    } catch (error) {
      _setStatusIfChanged(MobileCameraRelayStatus.failed);
      _setInfoMessageIfChanged('Error al abrir la camara del celular.');
    }
  }

  CameraDescription _pickPreferredCamera(List<CameraDescription> cameras) {
    return cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
  }

  void _handleCameraImage(CameraImage image) {
    if (!_streamRequested || _baseUrl == null) {
      return;
    }

    if (_uploadInProgress) {
      _droppedBusyFrameCount++;
      _logDroppedBusyFrame();
      return;
    }

    final lastFrameAt = lastFrameSentAt.value;
    if (lastFrameAt != null &&
        DateTime.now().difference(lastFrameAt) < _frameInterval) {
      _intervalSkippedFrameCount++;
      _logSkippedIntervalFrame();
      return;
    }

    final jpegBytes = _encodeCameraImage(image);
    if (jpegBytes == null || jpegBytes.isEmpty) {
      return;
    }

    _uploadInProgress = true;
    lastFrameSentAt.value = DateTime.now();
    unawaited(_uploadFrame(jpegBytes));
  }

  Uint8List? _encodeCameraImage(CameraImage image) {
    switch (image.format.group) {
      case ImageFormatGroup.jpeg:
        if (image.planes.isEmpty) {
          return null;
        }
        return _normalizeJpegBytes(image.planes.first.bytes);
      case ImageFormatGroup.bgra8888:
        return _encodeBgra8888(image);
      case ImageFormatGroup.yuv420:
        return _encodeYuv420(image);
      default:
        return null;
    }
  }

  Uint8List _normalizeJpegBytes(Uint8List jpegBytes) {
    if (!Platform.isAndroid) {
      return jpegBytes;
    }

    final decoded = img.decodeImage(jpegBytes);
    if (decoded == null) {
      return jpegBytes;
    }

    return _encodeNormalizedJpeg(decoded);
  }

  Uint8List _encodeBgra8888(CameraImage image) {
    final output = img.Image(width: image.width, height: image.height);
    final plane = image.planes.first;
    final bytes = plane.bytes;
    final rowStride = plane.bytesPerRow;

    for (var y = 0; y < image.height; y++) {
      final rowOffset = y * rowStride;
      for (var x = 0; x < image.width; x++) {
        final offset = rowOffset + (x * 4);
        final blue = bytes[offset];
        final green = bytes[offset + 1];
        final red = bytes[offset + 2];
        final alpha = bytes[offset + 3];
        output.setPixelRgba(x, y, red, green, blue, alpha);
      }
    }

    return _encodeNormalizedJpeg(output);
  }

  Uint8List _encodeYuv420(CameraImage image) {
    final output = img.Image(width: image.width, height: image.height);
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final yRowStride = yPlane.bytesPerRow;
    final uRowStride = uPlane.bytesPerRow;
    final vRowStride = vPlane.bytesPerRow;
    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;

    for (var y = 0; y < image.height; y++) {
      final uvRow = y >> 1;
      for (var x = 0; x < image.width; x++) {
        final yValue = yBytes[(y * yRowStride) + x];
        final uvColumn = x >> 1;
        final uValue = uBytes[(uvRow * uRowStride) + (uvColumn * uPixelStride)];
        final vValue = vBytes[(uvRow * vRowStride) + (uvColumn * vPixelStride)];

        final red = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        final green =
            (yValue - (0.344136 * (uValue - 128)) - (0.714136 * (vValue - 128)))
                .round()
                .clamp(0, 255);
        final blue = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

        output.setPixelRgb(x, y, red, green, blue);
      }
    }

    return _encodeNormalizedJpeg(output);
  }

  Uint8List _encodeNormalizedJpeg(img.Image image) {
    final normalizedImage = _normalizeFrameOrientation(image);
    final resizedImage = _resizeForUpload(normalizedImage);
    return img.encodeJpg(resizedImage, quality: PerformanceConfig.jpegQuality);
  }

  img.Image _resizeForUpload(img.Image image) {
    final sourceWidth = image.width;
    final sourceHeight = image.height;
    final maxWidth = PerformanceConfig.maxFrameWidth;
    final maxHeight = PerformanceConfig.maxFrameHeight;

    if (sourceWidth <= maxWidth && sourceHeight <= maxHeight) {
      return image;
    }

    final widthScale = maxWidth / sourceWidth;
    final heightScale = maxHeight / sourceHeight;
    final scale = widthScale < heightScale ? widthScale : heightScale;
    final resizedWidth = ((sourceWidth * scale).round()).clamp(1, maxWidth);
    final resizedHeight = ((sourceHeight * scale).round()).clamp(1, maxHeight);

    return img.copyResize(
      image,
      width: resizedWidth,
      height: resizedHeight,
      interpolation: img.Interpolation.average,
    );
  }

  img.Image _normalizeFrameOrientation(img.Image image) {
    if (!Platform.isAndroid) {
      return image;
    }

    final rotation = _frameRotationDegrees();
    if (rotation == 0) {
      return image;
    }

    // El stream crudo llega en la orientacion fisica del sensor, no como la
    // vista previa en pantalla. Aqui lo enderezamos antes de subirlo.
    return img.copyRotate(image, angle: rotation);
  }

  int _frameRotationDegrees() {
    final cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return 0;
    }

    final deviceOrientation =
        cameraController.value.lockedCaptureOrientation ??
        cameraController.value.deviceOrientation;
    final sensorOrientation = cameraController.description.sensorOrientation;
    final isFrontFacing =
        cameraController.description.lensDirection == CameraLensDirection.front;

    var deviceDegrees = switch (deviceOrientation) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeRight => 90,
      DeviceOrientation.portraitDown => 180,
      DeviceOrientation.landscapeLeft => 270,
    };

    if (isFrontFacing) {
      deviceDegrees *= -1;
    }

    return (deviceDegrees + sensorOrientation + 360) % 360;
  }

  Future<void> _uploadFrame(Uint8List jpegBytes) async {
    final stopwatch = Stopwatch()..start();
    _uploadAttemptCount++;
    _logUploadStarted(jpegBytes.length);

    try {
      final backendApiRepository = _backendApiRepository;
      if (backendApiRepository == null) {
        _logUploadFinished(
          elapsed: stopwatch.elapsed,
          outcome: 'skipped-no-backend',
        );
        return;
      }

      await backendApiRepository.sendFrame(jpegBytes);
      _uploadedFrameCount++;
      _setStatusIfChanged(MobileCameraRelayStatus.streaming);
      _setInfoMessageIfChanged(
        'Camara del celular activa. Backend procesando frames remotos.',
      );
      _logFrameMetrics(stopwatch.elapsed);
    } on TimeoutException catch (error) {
      _failedFrameCount++;
      if (_streamRequested) {
        _setStatusIfChanged(MobileCameraRelayStatus.streaming);
        _setInfoMessageIfChanged(
          'El backend tardo demasiado en responder un frame. Reintentando...',
        );
      }
      _logUploadTimeout(stopwatch.elapsed, error);
    } catch (error) {
      _failedFrameCount++;
      if (_streamRequested) {
        _setStatusIfChanged(MobileCameraRelayStatus.streaming);
        _setInfoMessageIfChanged(
          'No se pudo enviar un frame al backend. Reintentando...',
        );
      }
      if (kDebugMode) {
        debugPrint(
          'MobileCameraRelayService -> frame failed after '
          '${stopwatch.elapsedMilliseconds}ms '
          '(errors=$_failedFrameCount, dropped=$_droppedBusyFrameCount)',
        );
      }
    } finally {
      _logUploadFinished(
        elapsed: stopwatch.elapsed,
        outcome: _streamRequested ? 'ready-next-frame' : 'relay-stopped',
      );
      _uploadInProgress = false;
    }
  }

  void _logFrameMetrics(Duration elapsed) {
    if (!kDebugMode) {
      return;
    }

    if (_uploadedFrameCount % PerformanceConfig.performanceLogSampleSize != 0) {
      return;
    }

    debugPrint(
      'MobileCameraRelayService -> frames=$_uploadedFrameCount '
      'last=${elapsed.inMilliseconds}ms '
      'failed=$_failedFrameCount dropped=$_droppedBusyFrameCount '
      'interval_skips=$_intervalSkippedFrameCount '
      'quality=${PerformanceConfig.jpegQuality} '
      'limit=${PerformanceConfig.maxFrameWidth}x${PerformanceConfig.maxFrameHeight}',
    );
  }

  void _logDroppedBusyFrame() {
    if (!kDebugMode) {
      return;
    }

    final count = _droppedBusyFrameCount;
    if (count != 1 && count % PerformanceConfig.performanceLogSampleSize != 0) {
      return;
    }

    debugPrint(
      'MobileCameraRelayService -> frame dropped while upload busy '
      '(count=$count)',
    );
  }

  void _logSkippedIntervalFrame() {
    if (!kDebugMode) {
      return;
    }

    final count = _intervalSkippedFrameCount;
    if (count != 1 &&
        count % (PerformanceConfig.performanceLogSampleSize * 2) != 0) {
      return;
    }

    debugPrint(
      'MobileCameraRelayService -> frame skipped by interval '
      '(count=$count, every=${_frameInterval.inMilliseconds}ms)',
    );
  }

  void _logUploadStarted(int byteLength) {
    if (!kDebugMode) {
      return;
    }

    final count = _uploadAttemptCount;
    if (count != 1 && count % PerformanceConfig.performanceLogSampleSize != 0) {
      return;
    }

    debugPrint(
      'MobileCameraRelayService -> upload started '
      '(attempt=$count, bytes=$byteLength)',
    );
  }

  void _logUploadFinished({
    required Duration elapsed,
    required String outcome,
  }) {
    if (!kDebugMode) {
      return;
    }

    final count = _uploadAttemptCount;
    if (count != 1 && count % PerformanceConfig.performanceLogSampleSize != 0) {
      return;
    }

    debugPrint(
      'MobileCameraRelayService -> upload finished '
      '(attempt=$count, outcome=$outcome, ${elapsed.inMilliseconds}ms)',
    );
  }

  void _logUploadTimeout(Duration elapsed, TimeoutException error) {
    if (!kDebugMode) {
      return;
    }

    debugPrint(
      'MobileCameraRelayService -> upload timeout after '
      '${elapsed.inMilliseconds}ms: ${error.message ?? 'sin mensaje'}',
    );
  }

  String _normalizeBaseUrl(String host, int port) {
    var normalizedHost = host.trim();
    var normalizedPort = port;
    var scheme = 'http';

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

    normalizedHost = normalizedHost
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceAll('/', '');

    return '$scheme://$normalizedHost:$normalizedPort';
  }

  Future<void> _disposeCameraController() async {
    final cameraController = _controller;
    _controller = null;
    if (cameraController != null) {
      await cameraController.dispose();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      final shouldResumeStream = _streamRequested;
      final baseUrl = _baseUrl;
      final camera = _selectedCamera ?? cameraController.description;

      unawaited(_disposeCameraController());
      if (supported) {
        _setStatusIfChanged(MobileCameraRelayStatus.idle);
        _setInfoMessageIfChanged('Camara del celular en pausa.');
      }

      _selectedCamera = camera;
      _baseUrl = baseUrl;
      _streamRequested = shouldResumeStream;
    } else if (state == AppLifecycleState.resumed) {
      if (_selectedCamera == null) {
        return;
      }
      unawaited(_resumeAfterLifecycle());
    }
  }

  Future<void> _resumeAfterLifecycle() async {
    await _ensureCameraReady();

    if (_streamRequested && _baseUrl != null) {
      final uri = Uri.parse(_baseUrl!);
      await startRelay(host: _baseUrl!, port: uri.port);
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _client?.close();
    unawaited(stopRelay(disposeCamera: true));
    super.onClose();
  }

  void _setStatusIfChanged(MobileCameraRelayStatus nextStatus) {
    if (status.value == nextStatus) {
      return;
    }

    status.value = nextStatus;
  }

  void _setInfoMessageIfChanged(String nextMessage) {
    if (infoMessage.value == nextMessage) {
      return;
    }

    infoMessage.value = nextMessage;
  }
}
