import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:movilcontrol/app/data/enums/bluetooth_output_mode.dart';
import 'package:movilcontrol/app/data/enums/buzzer_command.dart';
import 'package:movilcontrol/app/data/enums/car_command.dart';
import 'package:movilcontrol/app/data/models/auto_state.dart';
import 'package:movilcontrol/app/modules/home/controllers/bluetooth_controller.dart';
import 'package:movilcontrol/app/services/auto_state_polling_service.dart';
import 'package:movilcontrol/app/services/bluetooth_command_service.dart';
import 'package:movilcontrol/app/services/mock_bluetooth_command_service.dart';

import 'test_helpers/fake_home_services.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  group('BluetoothController', () {
    test('stores last command and payload after sending', () async {
      final service = MockBluetoothCommandService();
      final controller = BluetoothController(
        bluetoothService: service,
        enableStateSync: false,
        startConnected: false,
      );

      await controller.connect();
      await controller.sendCarCommand(CarCommand.forward);

      expect(controller.isConnected.value, isTrue);
      expect(controller.lastCommand.value, CarCommand.forward);
      expect(controller.lastPayload.value, 'F');
      expect(service.lastCommand, 'F');
    });

    test(
      'does not resend duplicated commands when hand status stays equal',
      () async {
        final service = MockBluetoothCommandService();
        final controller = BluetoothController(
          bluetoothService: service,
          enableStateSync: false,
          startConnected: false,
        );

        await controller.connect();
        await controller.sendCommandFromHandStatus('MANO ABIERTA');
        await controller.sendCommandFromHandStatus('MANO ABIERTA');

        expect(service.sendCallCount, 1);

        await controller.sendCommandFromHandStatus('MANO CERRADA');

        expect(service.sendCallCount, 2);
        expect(controller.lastCommand.value, CarCommand.stop);
        expect(controller.lastPayload.value, 'S');
      },
    );

    test('sends buzzer on when hand is closed in buzzer mode', () async {
      final service = MockBluetoothCommandService();
      final controller = BluetoothController(
        bluetoothService: service,
        enableStateSync: false,
        startConnected: false,
        initialOutputMode: BluetoothOutputMode.buzzerReal,
      );

      await controller.connect();
      controller.enableBuzzerRealMode();
      await controller.sendBuzzerCommandFromHandStatus('MANO CERRADA');

      expect(controller.lastBuzzerCommand.value, BuzzerCommand.on);
      expect(controller.lastCommand.value, isNull);
      expect(controller.lastPayload.value, '1');
      expect(service.lastCommand, '1');
    });

    test('sends buzzer off when hand is open in buzzer mode', () async {
      final service = MockBluetoothCommandService();
      final controller = BluetoothController(
        bluetoothService: service,
        enableStateSync: false,
        startConnected: false,
        initialOutputMode: BluetoothOutputMode.buzzerReal,
      );

      await controller.connect();
      controller.enableBuzzerRealMode();
      await controller.sendBuzzerCommandFromHandStatus('MANO ABIERTA');

      expect(controller.lastBuzzerCommand.value, BuzzerCommand.off);
      expect(controller.lastPayload.value, '0');
      expect(service.lastCommand, '0');
    });

    test('sends buzzer off when no hand is detected in buzzer mode', () async {
      final service = MockBluetoothCommandService();
      final controller = BluetoothController(
        bluetoothService: service,
        enableStateSync: false,
        startConnected: false,
        initialOutputMode: BluetoothOutputMode.buzzerReal,
      );

      await controller.connect();
      controller.enableBuzzerRealMode();
      await controller.sendBuzzerCommandFromHandStatus('none');

      expect(controller.lastBuzzerCommand.value, BuzzerCommand.off);
      expect(controller.lastPayload.value, '0');
      expect(service.lastCommand, '0');
    });

    test('does not resend duplicated buzzer payloads', () async {
      final service = MockBluetoothCommandService();
      final controller = BluetoothController(
        bluetoothService: service,
        enableStateSync: false,
        startConnected: false,
        initialOutputMode: BluetoothOutputMode.buzzerReal,
      );

      await controller.connect();
      controller.enableBuzzerRealMode();
      await controller.sendBuzzerCommandFromHandStatus('MANO CERRADA');
      await controller.sendBuzzerCommandFromHandStatus('MANO CERRADA');

      expect(service.sendCallCount, 1);
      expect(controller.lastPayload.value, '1');
    });

    test('does not resend duplicated buzzer off payloads', () async {
      final service = MockBluetoothCommandService();
      final controller = BluetoothController(
        bluetoothService: service,
        enableStateSync: false,
        startConnected: false,
        initialOutputMode: BluetoothOutputMode.buzzerReal,
      );

      await controller.connect();
      controller.enableBuzzerRealMode();
      await controller.sendBuzzerCommandFromHandStatus('MANO ABIERTA');
      await controller.sendBuzzerCommandFromHandStatus('MANO ABIERTA');

      expect(service.sendCallCount, 1);
      expect(controller.lastPayload.value, '0');
    });

    test('loads paired devices and selects the first one by default', () async {
      final service = MockBluetoothCommandService()
        ..pairedDevices = const <BluetoothDeviceInfo>[
          BluetoothDeviceInfo(name: 'HC-05 Sala', address: 'AA:BB:01'),
          BluetoothDeviceInfo(name: 'HC-06 Taller', address: 'AA:BB:02'),
        ];
      final controller = BluetoothController(
        bluetoothService: service,
        enableStateSync: false,
        startConnected: false,
      );

      await controller.refreshPairedDevices();

      expect(controller.pairedDevices, hasLength(2));
      expect(controller.selectedDeviceAddress.value, 'AA:BB:01');
      expect(controller.selectedDeviceName.value, 'HC-05 Sala');
    });

    test('connects using the selected paired device address', () async {
      final service = MockBluetoothCommandService()
        ..pairedDevices = const <BluetoothDeviceInfo>[
          BluetoothDeviceInfo(name: 'HC-05 Sala', address: 'AA:BB:01'),
          BluetoothDeviceInfo(name: 'HC-06 Taller', address: 'AA:BB:02'),
        ];
      final controller = BluetoothController(
        bluetoothService: service,
        enableStateSync: false,
        startConnected: false,
      );

      await controller.refreshPairedDevices();
      controller.selectDevice('AA:BB:02');
      await controller.connectSelectedDevice();

      expect(controller.isConnected.value, isTrue);
      expect(service.lastConnectAddress, 'AA:BB:02');
      expect(controller.connectedDeviceAddress.value, 'AA:BB:02');
      expect(controller.connectedDeviceName.value, 'HC-06 Taller');
    });

    test(
      'enables manual buzzer control after backend reports an open hand',
      () async {
        final service = MockBluetoothCommandService();
        final polling = FakeAutoStatePollingService();
        final controller = BluetoothController(
          bluetoothService: service,
          pollingService: polling,
          startConnected: false,
          enableStateSync: true,
        );

        controller.onInit();
        expect(controller.isManualBuzzerControlEnabled.value, isFalse);
        expect(controller.outputMode.value, BluetoothOutputMode.autoVirtual);

        polling.latestState.value = _buildState(
          handDetected: true,
          handState: 'MANO ABIERTA',
          fingersUp: 5,
          carMoving: true,
        );
        await Future<void>.delayed(Duration.zero);

        expect(controller.isManualBuzzerControlEnabled.value, isTrue);
        expect(controller.outputMode.value, BluetoothOutputMode.autoVirtual);

        controller.enableAutoVirtualMode();
        expect(controller.isManualBuzzerControlEnabled.value, isFalse);

        polling.latestState.value = _buildState(
          handDetected: true,
          handState: 'MANO ABIERTA',
          fingersUp: 5,
          carMoving: true,
        );
        await Future<void>.delayed(Duration.zero);

        expect(controller.isManualBuzzerControlEnabled.value, isFalse);

        polling.latestState.value = _buildState(
          handDetected: true,
          handState: 'MANO CERRADA',
          fingersUp: 0,
          carMoving: false,
        );
        await Future<void>.delayed(Duration.zero);

        polling.latestState.value = _buildState(
          handDetected: true,
          handState: 'MANO ABIERTA',
          fingersUp: 5,
          carMoving: true,
        );
        await Future<void>.delayed(Duration.zero);

        expect(controller.isManualBuzzerControlEnabled.value, isTrue);
        controller.onClose();
      },
    );

    test(
      'manual buzzer buttons do not send when bluetooth is disconnected',
      () async {
        final service = MockBluetoothCommandService();
        final controller = BluetoothController(
          bluetoothService: service,
          enableStateSync: false,
          startConnected: false,
          initialOutputMode: BluetoothOutputMode.buzzerReal,
        );

        await controller.sendBuzzerOn();
        await controller.sendBuzzerOff();

        expect(service.sendCallCount, 0);
        expect(
          controller.errorMessage.value,
          'Conecta el modulo Bluetooth antes de enviar comandos manuales.',
        );
      },
    );

    test(
      'backend disconnected state does not break bluetooth connection',
      () async {
        final service = MockBluetoothCommandService();
        final polling = FakeAutoStatePollingService();
        final controller = BluetoothController(
          bluetoothService: service,
          pollingService: polling,
          startConnected: false,
          enableStateSync: true,
        );

        controller.onInit();
        await controller.connect();
        polling.status.value = SocketConnectionStatus.disconnected;
        polling.errorMessage.value = 'Backend caido';

        await controller.sendBuzzerOn();

        expect(controller.isConnected.value, isTrue);
        expect(service.sendCallCount, 1);
        expect(service.lastCommand, '1');
        controller.onClose();
      },
    );

    test(
      'bluetooth disconnected state does not break backend state flow',
      () async {
        final service = MockBluetoothCommandService();
        final polling = FakeAutoStatePollingService();
        final controller = BluetoothController(
          bluetoothService: service,
          pollingService: polling,
          startConnected: false,
          enableStateSync: true,
        );

        controller.onInit();
        polling.status.value = SocketConnectionStatus.connected;
        polling.latestState.value = _buildState(
          handDetected: true,
          handState: 'MANO ABIERTA',
          fingersUp: 5,
          carMoving: true,
        );
        await Future<void>.delayed(Duration.zero);

        expect(polling.status.value, SocketConnectionStatus.connected);
        expect(controller.isManualBuzzerControlEnabled.value, isTrue);
        expect(service.sendCallCount, 0);
        controller.onClose();
      },
    );
  });
}

AutoState _buildState({
  required bool handDetected,
  required String handState,
  required int fingersUp,
  required bool carMoving,
}) {
  return AutoState(
    timestamp: DateTime(2026, 6, 4, 12, 0),
    handDetected: handDetected,
    handState: handState,
    fingersUp: fingersUp,
    carMoving: carMoving,
    carX: carMoving ? 420 : 0,
    carY: 350,
    speed: carMoving ? 14 : 8,
    backendReady: true,
    backendMessage: 'Backend listo',
    backendLastError: '',
    previewBytes: null,
    cameraFrameWidth: null,
    cameraFrameHeight: null,
  );
}
