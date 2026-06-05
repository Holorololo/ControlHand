import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movilcontrol/app/services/mobile_camera_relay_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lifecycle resumed restarts relay when it was active', () async {
    final service = _TestMobileCameraRelayService(
      ensureCameraReadyHook: () async {},
    );
    service.onInit();
    service.debugSeedLifecycleState(
      selectedCamera: const CameraDescription(
        name: 'test-camera',
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 90,
      ),
      streamRequested: true,
      baseUrl: 'http://127.0.0.1:5000',
    );

    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(service.lastLifecycleEvent, 'resumed');
    expect(service.restartCount, 1);
    service.onClose();
  });
}

class _TestMobileCameraRelayService extends MobileCameraRelayService {
  _TestMobileCameraRelayService({super.ensureCameraReadyHook});

  int restartCount = 0;

  @override
  bool get supported => true;

  @override
  Future<void> startRelay({required String host, required int port}) async {
    restartCount++;
  }
}
