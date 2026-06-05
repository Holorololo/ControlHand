import 'package:camera/camera.dart';

enum FramePipelineProfile { quality, balanced, fast }

class PerformanceConfig {
  const PerformanceConfig._();

  static const FramePipelineProfile framePipelineProfile =
      FramePipelineProfile.balanced;
  static const bool _isQuality =
      framePipelineProfile == FramePipelineProfile.quality;
  static const bool _isBalanced =
      framePipelineProfile == FramePipelineProfile.balanced;

  static const int backendRequestTimeoutMs = _isQuality
      ? 3800
      : (_isBalanced ? 3200 : 2200);
  static const int frameUploadTimeoutMs = _isQuality
      ? 3400
      : (_isBalanced ? 3000 : 2000);
  static const int bluetoothConnectTimeoutMs = 6500;
  static const int bluetoothSendTimeoutMs = 2500;
  static const int pollingIntervalMs = _isQuality
      ? 480
      : (_isBalanced ? 420 : 360);
  static const int backgroundPollingIntervalMs = _isQuality
      ? 420
      : (_isBalanced ? 340 : 280);
  static const int previewRefreshIntervalMs = _isQuality
      ? 1000
      : (_isBalanced ? 1200 : 1400);
  static const int reconnectBaseDelayMs = _isQuality
      ? 2400
      : (_isBalanced ? 1800 : 1200);
  static const int reconnectMaxDelayMs = _isQuality
      ? 7000
      : (_isBalanced ? 6000 : 4000);

  static const int frameSendIntervalMs = _isQuality
      ? 380
      : (_isBalanced ? 320 : 260);
  static const int jpegQuality = _isQuality ? 65 : (_isBalanced ? 60 : 50);
  static const int maxFrameWidth = _isQuality ? 720 : (_isBalanced ? 640 : 560);
  static const int maxFrameHeight = _isQuality
      ? 960
      : (_isBalanced ? 960 : 720);
  static const ResolutionPreset mobileCameraResolutionPreset =
      ResolutionPreset.medium;

  static const int backendProcessingWidth = _isQuality
      ? 720
      : (_isBalanced ? 640 : 560);
  static const int backendPreviewWidth = _isQuality
      ? 480
      : (_isBalanced ? 480 : 320);
  static const int backendPreviewQuality = _isQuality
      ? 65
      : (_isBalanced ? 60 : 50);
  static const int backendStableFrames = _isQuality ? 3 : (_isBalanced ? 2 : 2);
  static const int backendPreviewIntervalMs = _isQuality
      ? 900
      : (_isBalanced ? 1000 : 1200);

  static const int previewImageCacheWidth = _isQuality
      ? 720
      : (_isBalanced ? 640 : 480);
  static const int performanceLogSampleSize = 12;
  static const bool enableOptimizedAnimations = true;
  static const bool performanceMode = true;
  static const int uiAnimationDurationMs = performanceMode ? 120 : 190;
  static const int uiAnimationFastDurationMs = performanceMode ? 90 : 150;
  static const bool enableAnimatedCar = false;
}
