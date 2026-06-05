import 'package:flutter_test/flutter_test.dart';

import 'package:movilcontrol/app/config/performance_config.dart';

void main() {
  group('PerformanceConfig', () {
    test('uses balanced frame pipeline defaults', () {
      expect(
        PerformanceConfig.framePipelineProfile,
        FramePipelineProfile.balanced,
      );
      expect(PerformanceConfig.frameSendIntervalMs, inInclusiveRange(280, 350));
      expect(
        PerformanceConfig.backgroundPollingIntervalMs,
        inInclusiveRange(300, 450),
      );
      expect(PerformanceConfig.pollingIntervalMs, inInclusiveRange(300, 450));
    });

    test('keeps image quality in a safe detection range', () {
      expect(PerformanceConfig.jpegQuality, inInclusiveRange(55, 65));
      expect(PerformanceConfig.maxFrameWidth, greaterThanOrEqualTo(640));
      expect(
        PerformanceConfig.backendProcessingWidth,
        greaterThanOrEqualTo(640),
      );
      expect(
        PerformanceConfig.previewRefreshIntervalMs,
        greaterThan(PerformanceConfig.backgroundPollingIntervalMs),
      );
      expect(PerformanceConfig.backendStableFrames, inInclusiveRange(2, 3));
    });
  });
}
