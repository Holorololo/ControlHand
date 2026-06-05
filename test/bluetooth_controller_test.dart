import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:movilcontrol/app/data/enums/bluetooth_output_mode.dart';
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
    test('stores last command and payload after manual send', () async {
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
      'maps finger count 1 to left and finger count 4 to backward',
      () async {
        final service = MockBluetoothCommandService();
        final controller = BluetoothController(
          bluetoothService: service,
          enableStateSync: false,
          startConnected: false,
        );

        await controller.connect();
        await controller.sendCommandFromHandStatus(
          'partial',
          handDetected: true,
          fingerCount: 1,
          backendCommand: 'left',
          payload: 'L',
        );
        await controller.sendCommandFromHandStatus(
          'partial',
          handDetected: true,
          fingerCount: 4,
          backendCommand: 'backward',
          payload: 'B',
        );

        expect(service.sendCallCount, 2);
        expect(controller.lastCommand.value, CarCommand.backward);
        expect(controller.lastPayload.value, 'B');
      },
    );

    test(
      'does not resend duplicated automatic commands for the same state',
      () async {
        final service = MockBluetoothCommandService();
        final controller = BluetoothController(
          bluetoothService: service,
          enableStateSync: false,
          startConnected: false,
        );

        await controller.connect();
        await controller.sendCommandFromHandStatus(
          'open',
          handDetected: true,
          fingerCount: 5,
          backendCommand: 'forward',
          payload: 'F',
        );
        await controller.sendCommandFromHandStatus(
          'open',
          handDetected: true,
          fingerCount: 5,
          backendCommand: 'forward',
          payload: 'F',
        );

        expect(service.sendCallCount, 1);

        await controller.sendCommandFromHandStatus(
          'closed',
          handDetected: true,
          fingerCount: 0,
          backendCommand: 'stop',
          payload: 'S',
        );

        expect(service.sendCallCount, 2);
        expect(controller.lastCommand.value, CarCommand.stop);
        expect(controller.lastPayload.value, 'S');
      },
    );

    test('horn payload H is sent once when 3 fingers stay stable', () async {
      final service = MockBluetoothCommandService();
      final polling = FakeAutoStatePollingService();
      final controller = BluetoothController(
        bluetoothService: service,
        pollingService: polling,
        startConnected: false,
        enableStateSync: true,
        initialOutputMode: BluetoothOutputMode.buzzerReal,
      );

      controller.onInit();
      await controller.connect();
      controller.enableBuzzerRealMode();

      polling.latestState.value = _buildState(
        handDetected: true,
        handStatus: 'partial',
        handState: '3 DEDOS',
        fingersUp: 3,
        command: 'horn',
        payload: 'H',
        carMoving: false,
      );
      await Future<void>.delayed(Duration.zero);

      polling.latestState.value = _buildState(
        handDetected: true,
        handStatus: 'partial',
        handState: '3 DEDOS',
        fingersUp: 3,
        command: 'horn',
        payload: 'H',
        carMoving: false,
      );
      await Future<void>.delayed(Duration.zero);

      expect(service.sendCallCount, 1);
      expect(controller.lastCommand.value, CarCommand.horn);
      expect(controller.lastPayload.value, 'H');
      controller.onClose();
    });

    test(
      'manual horn can be resent after debounce without spamming instantly',
      () async {
        final service = MockBluetoothCommandService();
        final controller = BluetoothController(
          bluetoothService: service,
          enableStateSync: false,
          startConnected: false,
        );

        await controller.connect();
        await controller.sendHorn();
        await controller.sendHorn();
        await Future<void>.delayed(const Duration(milliseconds: 220));
        await controller.sendHorn();

        expect(service.sendCallCount, 2);
        expect(controller.lastPayload.value, 'H');
      },
    );

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
      'manual commands do not send when bluetooth is disconnected',
      () async {
        final service = MockBluetoothCommandService();
        final controller = BluetoothController(
          bluetoothService: service,
          enableStateSync: false,
          startConnected: false,
        );

        await controller.sendForward();
        await controller.sendHorn();

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

        await controller.sendForward();

        expect(controller.isConnected.value, isTrue);
        expect(service.sendCallCount, 1);
        expect(service.lastCommand, 'F');
        controller.onClose();
      },
    );
  });
}

AutoState _buildState({
  required bool handDetected,
  required String handStatus,
  required String handState,
  required int fingersUp,
  required String command,
  required String payload,
  required bool carMoving,
}) {
  return AutoState(
    timestamp: DateTime(2026, 6, 5, 12, 0),
    handDetected: handDetected,
    normalizedHandStatus: handStatus,
    handState: handState,
    fingersUp: fingersUp,
    command: command,
    payload: payload,
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
