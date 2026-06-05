import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movilcontrol/app/services/mobile_camera_relay_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const backCamera = CameraDescription(
    name: 'back-camera',
    lensDirection: CameraLensDirection.back,
    sensorOrientation: 90,
  );
  const frontCamera = CameraDescription(
    name: 'front-camera',
    lensDirection: CameraLensDirection.front,
    sensorOrientation: 90,
  );

  test('lifecycle resumed restarts relay when it was active', () async {
    final service = _TestMobileCameraRelayService(
      ensureCameraReadyHook: () async {},
      availableCamerasHook: () async => const <CameraDescription>[backCamera],
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

  test('toggleCamera does nothing when only one camera is available', () async {
    final service = _TestMobileCameraRelayService(
      ensureCameraReadyHook: () async {},
      availableCamerasHook: () async => const <CameraDescription>[backCamera],
    );
    service.onInit();

    await service.preparePreview();
    await service.toggleCamera();

    expect(service.canSwitchCamera.value, isFalse);
    expect(service.isSwitchingCamera.value, isFalse);
    expect(service.isFrontCameraSelected.value, isFalse);
    expect(service.cameraLensLabel.value, 'Camara trasera');
    service.onClose();
  });

  test('toggleCamera flips camera and exposes switching state', () async {
    Completer<void>? switchCompleter;
    final service = _TestMobileCameraRelayService(
      ensureCameraReadyHook: () async {
        final completer = switchCompleter;
        if (completer != null) {
          await completer.future;
        }
      },
      availableCamerasHook: () async => const <CameraDescription>[
        backCamera,
        frontCamera,
      ],
    );
    service.onInit();

    await service.preparePreview();
    expect(service.canSwitchCamera.value, isTrue);
    expect(service.isFrontCameraSelected.value, isFalse);
    expect(service.cameraLensLabel.value, 'Camara trasera');

    switchCompleter = Completer<void>();
    final switchFuture = service.toggleCamera();
    await Future<void>.delayed(Duration.zero);

    expect(service.isSwitchingCamera.value, isTrue);

    switchCompleter.complete();
    await switchFuture;

    expect(service.isSwitchingCamera.value, isFalse);
    expect(service.isFrontCameraSelected.value, isTrue);
    expect(service.cameraLensLabel.value, 'Camara frontal');
    service.onClose();
  });
}

class _TestMobileCameraRelayService extends MobileCameraRelayService {
  _TestMobileCameraRelayService({
    super.ensureCameraReadyHook,
    super.availableCamerasHook,
  });

  int restartCount = 0;

  @override
  bool get supported => true;

  @override
  Future<void> startRelay({required String host, required int port}) async {
    restartCount++;
  }
}
