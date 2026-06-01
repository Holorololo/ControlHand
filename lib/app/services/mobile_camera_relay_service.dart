import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

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

  final Duration _frameInterval = const Duration(milliseconds: 320);
  static const int _frameJpegQuality = 90;

  CameraController? _controller;
  CameraDescription? _selectedCamera;
  http.Client? _client;
  String? _baseUrl;
  bool _streamRequested = false;
  bool _uploadInProgress = false;

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
      status.value = MobileCameraRelayStatus.idle;
      infoMessage.value =
          'La camara del celular se activara cuando te conectes al backend.';
    } else {
      status.value = MobileCameraRelayStatus.unsupported;
      infoMessage.value =
          'La camara del celular solo se usa en Android o iPhone.';
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
      status.value = MobileCameraRelayStatus.unsupported;
      return;
    }

    _streamRequested = true;
    _baseUrl = _normalizeBaseUrl(host, port);

    await _ensureCameraReady();

    final cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (!cameraController.value.isStreamingImages) {
      await cameraController.startImageStream(_handleCameraImage);
    }

    status.value = MobileCameraRelayStatus.streaming;
    infoMessage.value =
        'Camara del celular activa. Enviando frames a $_baseUrl.';
  }

  Future<void> stopRelay({bool disposeCamera = false}) async {
    _streamRequested = false;
    _baseUrl = null;

    final cameraController = _controller;
    if (cameraController != null && cameraController.value.isStreamingImages) {
      await cameraController.stopImageStream();
    }

    if (disposeCamera) {
      await _disposeCameraController();
      status.value = supported
          ? MobileCameraRelayStatus.idle
          : MobileCameraRelayStatus.unsupported;
      return;
    }

    if (hasPreview) {
      status.value = MobileCameraRelayStatus.ready;
      infoMessage.value = 'Camara del celular lista, sin enviar frames.';
    } else if (supported) {
      status.value = MobileCameraRelayStatus.idle;
      infoMessage.value =
          'La camara del celular se activara cuando te conectes al backend.';
    }
  }

  Future<void> _ensureCameraReady() async {
    if (hasPreview) {
      if (status.value == MobileCameraRelayStatus.initializing) {
        status.value = MobileCameraRelayStatus.ready;
      }
      return;
    }

    status.value = MobileCameraRelayStatus.initializing;
    infoMessage.value = 'Abriendo la camara del celular...';

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        status.value = MobileCameraRelayStatus.failed;
        infoMessage.value = 'No se encontro una camara disponible.';
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
        ResolutionPreset.high,
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
      status.value = MobileCameraRelayStatus.ready;
      infoMessage.value = 'Camara del celular lista.';
    } on CameraException catch (error) {
      if (error.code == 'CameraAccessDenied' ||
          error.code == 'CameraAccessDeniedWithoutPrompt' ||
          error.code == 'CameraAccessRestricted') {
        status.value = MobileCameraRelayStatus.permissionDenied;
        infoMessage.value = 'No se concedio acceso a la camara del celular.';
      } else {
        status.value = MobileCameraRelayStatus.failed;
        infoMessage.value = 'No se pudo inicializar la camara. ${error.code}';
      }
    } catch (error) {
      status.value = MobileCameraRelayStatus.failed;
      infoMessage.value = 'Error al abrir la camara del celular.';
    }
  }

  CameraDescription _pickPreferredCamera(List<CameraDescription> cameras) {
    return cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
  }

  void _handleCameraImage(CameraImage image) {
    if (!_streamRequested || _uploadInProgress || _baseUrl == null) {
      return;
    }

    final lastFrameAt = lastFrameSentAt.value;
    if (lastFrameAt != null &&
        DateTime.now().difference(lastFrameAt) < _frameInterval) {
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
    return img.encodeJpg(normalizedImage, quality: _frameJpegQuality);
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
    try {
      _client ??= http.Client();
      final response = await _client!
          .post(
            Uri.parse('$_baseUrl/frame'),
            headers: const <String, String>{'Content-Type': 'image/jpeg'},
            body: jpegBytes,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        status.value = MobileCameraRelayStatus.streaming;
        infoMessage.value =
            'Camara del celular activa. Backend procesando frames remotos.';
        return;
      }

      final decoded = _tryDecodeJson(response.body);
      final message =
          decoded['message']?.toString() ??
          'Respuesta HTTP ${response.statusCode} al subir frame.';
      status.value = MobileCameraRelayStatus.failed;
      infoMessage.value = message;
    } catch (error) {
      status.value = MobileCameraRelayStatus.failed;
      infoMessage.value =
          'No se pudo enviar el frame al backend. ${error.toString()}';
    } finally {
      _uploadInProgress = false;
    }
  }

  Map<String, dynamic> _tryDecodeJson(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Si no es JSON, devolvemos vacio y usamos el mensaje generico.
    }
    return const <String, dynamic>{};
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
        status.value = MobileCameraRelayStatus.idle;
        infoMessage.value = 'Camara del celular en pausa.';
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
}
