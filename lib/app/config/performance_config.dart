import 'package:camera/camera.dart';

class PerformanceConfig {
  const PerformanceConfig._();

  static const int backendRequestTimeoutMs = 4000;
  static const int frameUploadTimeoutMs = 3500;
  static const int bluetoothConnectTimeoutMs = 2500;
  static const int bluetoothSendTimeoutMs = 1200;
  static const int pollingIntervalMs = 500;
  static const int backgroundPollingIntervalMs = 850;
  static const int previewRefreshIntervalMs = 700;
  static const int reconnectBaseDelayMs = 3000;
  static const int reconnectMaxDelayMs = 9000;

  static const int frameSendIntervalMs = 450;
  static const int jpegQuality = 58;
  static const int maxFrameWidth = 720;
  static const int maxFrameHeight = 960;
  static const ResolutionPreset mobileCameraResolutionPreset =
      ResolutionPreset.medium;

  static const int previewImageCacheWidth = 720;
  static const int performanceLogSampleSize = 12;
  static const bool enableAnimatedCar = false;
}
