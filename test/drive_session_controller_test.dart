import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:movilcontrol/app/data/models/auto_state.dart';
import 'package:movilcontrol/app/modules/home/controllers/connection_controller.dart';
import 'package:movilcontrol/app/modules/home/controllers/drive_session_controller.dart';
import 'package:movilcontrol/app/services/auto_state_polling_service.dart';
import 'package:movilcontrol/app/services/backend_process_service.dart';
import 'package:movilcontrol/app/services/mobile_camera_relay_service.dart';

import 'test_helpers/fake_home_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  group('DriveSessionController', () {
    test('starts with safe initial hand and car state', () {
      final services = _registerServices();
      Get.put<ConnectionController>(
        TestConnectionController(autoConnect: false),
      );
      final controller = DriveSessionController();

      expect(controller.hasData, isFalse);
      expect(
        controller.handSummary,
        'Esperando estado HTTP del backend Flask.',
      );
      expect(controller.movementLabel, 'Auto detenido');
      expect(controller.packetLabel, 'Aun sin datos');
      expect(controller.cameraSummary, 'Esperando backend');
      expect(controller.statePreview, contains('"hand_detected": false'));
      expect(services.polling.previewStreamingToggles, isEmpty);
    });

    test('maps open hand to moving car and live preview summary', () {
      final services = _registerServices();
      Get.put<ConnectionController>(
        TestConnectionController(autoConnect: false),
      );
      final controller = DriveSessionController();
      final state = _buildState(
        handDetected: true,
        handState: 'MANO ABIERTA',
        fingersUp: 5,
        carMoving: true,
        previewBytes: Uint8List.fromList(<int>[1, 2, 3]),
        previewWidth: 1280,
        previewHeight: 720,
      );

      services.polling.latestState.value = state;
      services.polling.lastPacketAt.value = state.timestamp;

      expect(controller.handSummary, 'MANO ABIERTA');
      expect(controller.movementLabel, 'Auto avanzando');
      expect(
        controller.cameraSummary,
        'Vista en vivo recibida desde Flask/OpenCV.',
      );
      expect(controller.packetLabel, '12:34:56');
    });

    test('maps closed hand to stopped car', () {
      final services = _registerServices();
      Get.put<ConnectionController>(
        TestConnectionController(autoConnect: false),
      );
      final controller = DriveSessionController();
      final state = _buildState(
        handDetected: true,
        handState: 'MANO CERRADA',
        fingersUp: 0,
        carMoving: false,
        backendMessage: 'Detenido por gesto',
      );

      services.polling.latestState.value = state;

      expect(controller.handSummary, 'MANO CERRADA');
      expect(controller.movementLabel, 'Auto detenido');
      expect(controller.cameraSummary, 'Detenido por gesto');
    });

    test('maps no hand detected to a safe state', () {
      _registerServices();
      Get.put<ConnectionController>(
        TestConnectionController(autoConnect: false),
      );
      final controller = DriveSessionController();
      final state = _buildState(
        handDetected: false,
        handState: 'MANO ABIERTA',
        fingersUp: 0,
        carMoving: false,
        backendMessage: 'Sin mano',
      );

      Get.find<AutoStatePollingService>().latestState.value = state;

      expect(controller.handSummary, 'No se detecta mano.');
      expect(controller.movementLabel, 'Auto detenido');
      expect(controller.statePreview, contains('"hand_detected": false'));
    });

    test(
      'toggles diagnostics panel and preview streaming in mobile mode',
      () async {
        final services = _registerServices();
        services.mobile.supportedValue = true;
        Get.put<ConnectionController>(
          TestConnectionController(
            autoConnect: false,
            isMobileClientOverride: true,
          ),
        );
        final controller = TestDriveSessionController(
          isMobileClientOverride: true,
        );

        controller.prepareSessionExperience();
        expect(controller.showImmersiveMobileHome, isTrue);
        expect(services.mobile.preparePreviewCallCount, 1);
        expect(services.polling.previewStreamingToggles, <bool>[false]);

        await controller.openDiagnosticsPanel();
        expect(controller.isDiagnosticsVisible.value, isTrue);
        expect(services.polling.previewStreamingToggles.last, isTrue);

        controller.closeDiagnosticsPanel();
        expect(controller.isDiagnosticsVisible.value, isFalse);
        expect(services.polling.previewStreamingToggles.last, isFalse);
      },
    );

    test(
      'opening control center in mobile mode does not enable remote preview automatically',
      () async {
        final services = _registerServices();
        services.mobile.supportedValue = true;
        Get.put<ConnectionController>(
          TestConnectionController(
            autoConnect: false,
            isMobileClientOverride: true,
          ),
        );
        final controller = TestDriveSessionController(
          isMobileClientOverride: true,
        );

        controller.prepareSessionExperience();
        expect(services.polling.previewStreamingToggles, <bool>[false]);

        await controller.openControlCenter();
        expect(controller.isDiagnosticsVisible.value, isTrue);
        expect(services.polling.previewStreamingToggles, <bool>[false]);

        controller.closeControlCenter();
        expect(controller.isDiagnosticsVisible.value, isFalse);
        expect(services.polling.previewStreamingToggles, <bool>[false]);
      },
    );

    test('builds packet label, state preview and connected camera summary', () {
      final services = _registerServices();
      final connectionController = TestConnectionController(autoConnect: false);
      Get.put<ConnectionController>(connectionController);
      final controller = DriveSessionController();
      final state = _buildState(
        handDetected: true,
        handState: 'MANO ABIERTA',
        fingersUp: 5,
        carMoving: true,
        backendMessage: '',
      );

      services.polling.latestState.value = state;
      services.polling.lastPacketAt.value = state.timestamp;
      services.polling.status.value = SocketConnectionStatus.connected;

      expect(controller.packetLabel, '12:34:56');
      expect(
        controller.cameraSummary,
        'Conectado, esperando el primer frame de la camara.',
      );
      expect(controller.statePreview, contains('"hand_state": "MANO ABIERTA"'));
      expect(controller.statePreview, contains('"car_moving": true'));
    });
  });
}

_RegisteredDriveServices _registerServices() {
  final polling = FakeAutoStatePollingService();
  final backend = FakeBackendProcessService();
  final mobile = FakeMobileCameraRelayService();

  Get.put<AutoStatePollingService>(polling);
  Get.put<BackendProcessService>(backend);
  Get.put<MobileCameraRelayService>(mobile);

  return _RegisteredDriveServices(
    polling: polling,
    backend: backend,
    mobile: mobile,
  );
}

class _RegisteredDriveServices {
  const _RegisteredDriveServices({
    required this.polling,
    required this.backend,
    required this.mobile,
  });

  final FakeAutoStatePollingService polling;
  final FakeBackendProcessService backend;
  final FakeMobileCameraRelayService mobile;
}

AutoState _buildState({
  required bool handDetected,
  required String handState,
  required int fingersUp,
  required bool carMoving,
  String backendMessage = 'Backend listo',
  Uint8List? previewBytes,
  int? previewWidth,
  int? previewHeight,
}) {
  return AutoState(
    timestamp: DateTime(2026, 6, 1, 12, 34, 56),
    handDetected: handDetected,
    handState: handState,
    fingersUp: fingersUp,
    carMoving: carMoving,
    carX: carMoving ? 420 : 0,
    carY: 350,
    speed: carMoving ? 14 : 8,
    backendReady: true,
    backendMessage: backendMessage,
    backendLastError: '',
    previewBytes: previewBytes,
    cameraFrameWidth: previewWidth,
    cameraFrameHeight: previewHeight,
  );
}
