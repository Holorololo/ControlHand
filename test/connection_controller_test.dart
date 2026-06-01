import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:movilcontrol/app/modules/home/controllers/connection_controller.dart';
import 'package:movilcontrol/app/services/auto_socket_service.dart';
import 'package:movilcontrol/app/services/backend_process_service.dart';
import 'package:movilcontrol/app/services/mobile_camera_relay_service.dart';

import 'test_helpers/fake_home_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  group('ConnectionController', () {
    test('starts with expected initial desktop state', () {
      final services = _registerServices();
      final controller = TestConnectionController(autoConnect: false);

      expect(controller.hostTextController.text, '127.0.0.1');
      expect(controller.portTextController.text, '5000');
      expect(controller.statusLabel, 'Desconectado');
      expect(controller.backendStatusLabel, 'Backend inactivo');
      expect(controller.endpointLabel, 'http://127.0.0.1:5000');
      expect(controller.connectionHint, contains('Modo local listo'));
      expect(
        controller.backendCommand,
        ConnectionController.desktopBackendCommand,
      );
      expect(controller.connectionSectionTitle, 'Conexion local');
      expect(services.backend.canAutoStart, isTrue);
    });

    test('updates endpoint and hints when host and port change', () {
      final services = _registerServices();
      services.backend.canManageHostValue = false;
      final controller = TestConnectionController(autoConnect: false);

      controller.hostTextController.text = '192.168.1.25';
      controller.portTextController.text = '6000';

      expect(controller.endpointLabel, 'http://192.168.1.25:6000');
      expect(controller.connectionHint, contains('Con una IP remota'));
      expect(controller.backendActionHint, contains('levantar el backend'));
      expect(controller.canRestartManagedBackend, isFalse);
    });

    test('exposes connected and disconnected labels correctly', () {
      final services = _registerServices();
      final controller = TestConnectionController(autoConnect: false);

      services.socket.status.value = SocketConnectionStatus.connected;
      services.backend.status.value = BackendRuntimeStatus.running;
      expect(controller.statusLabel, 'Conectado');
      expect(controller.backendStatusLabel, 'Backend iniciado por Flutter');

      services.socket.status.value = SocketConnectionStatus.disconnected;
      services.backend.status.value = BackendRuntimeStatus.failed;
      expect(controller.statusLabel, 'Desconectado');
      expect(controller.backendStatusLabel, 'Fallo al iniciar backend');
    });

    test(
      'toggleConnection connects and disconnects through fake services',
      () async {
        final services = _registerServices();
        services.mobile.supportedValue = true;
        services.backend.canManageHostValue = true;
        final controller = TestConnectionController(autoConnect: false);

        controller.hostTextController.text = '127.0.0.1';
        controller.portTextController.text = '5000';

        await controller.toggleConnection();

        expect(services.backend.ensureStartedCallCount, 1);
        expect(services.backend.lastEnsureHost, '127.0.0.1');
        expect(services.backend.lastEnsurePort, 5000);
        expect(services.socket.connectCallCount, 1);
        expect(services.socket.lastConnectHost, '127.0.0.1');
        expect(services.socket.lastConnectPort, 5000);
        expect(services.mobile.stopRelayCallCount, 1);
        expect(services.mobile.startRelayCallCount, 1);

        await controller.toggleConnection();

        expect(services.socket.disconnectCallCount, 1);
        expect(services.mobile.stopRelayCallCount, 2);
      },
    );

    testWidgets('does not attempt connection when endpoint is invalid', (
      WidgetTester tester,
    ) async {
      final services = _registerServices();
      final controller = TestConnectionController(autoConnect: false);

      await tester.pumpWidget(
        const GetMaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );

      controller.hostTextController.text = '';
      controller.portTextController.text = 'abc';

      await controller.connect();
      await tester.pump();
      Get.closeAllSnackbars();
      await tester.pumpAndSettle();

      expect(services.backend.ensureStartedCallCount, 0);
      expect(services.socket.connectCallCount, 0);
      expect(services.mobile.startRelayCallCount, 0);
    });

    test(
      'exposes mobile command and loopback hint when mobile is simulated',
      () {
        final services = _registerServices();
        services.backend.canAutoStartValue = false;
        final controller = TestConnectionController(
          autoConnect: false,
          isMobileClientOverride: true,
        );

        expect(
          controller.backendCommand,
          ConnectionController.mobileBackendCommand,
        );
        expect(
          controller.connectionHint,
          contains('127.0.0.1 apunta al propio telefono'),
        );
        expect(controller.connectionSectionTitle, 'Conexion remota');
      },
    );
  });
}

_RegisteredConnectionServices _registerServices() {
  final socket = FakeAutoSocketService();
  final backend = FakeBackendProcessService();
  final mobile = FakeMobileCameraRelayService();

  Get.put<AutoSocketService>(socket);
  Get.put<BackendProcessService>(backend);
  Get.put<MobileCameraRelayService>(mobile);

  return _RegisteredConnectionServices(
    socket: socket,
    backend: backend,
    mobile: mobile,
  );
}

class _RegisteredConnectionServices {
  const _RegisteredConnectionServices({
    required this.socket,
    required this.backend,
    required this.mobile,
  });

  final FakeAutoSocketService socket;
  final FakeBackendProcessService backend;
  final FakeMobileCameraRelayService mobile;
}
