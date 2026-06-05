import 'package:flutter_test/flutter_test.dart';

import 'package:movilcontrol/app/data/enums/bluetooth_output_mode.dart';
import 'package:movilcontrol/app/data/enums/buzzer_command.dart';
import 'package:movilcontrol/app/data/enums/car_command.dart';
import 'package:movilcontrol/app/modules/home/controllers/bluetooth_controller.dart';
import 'package:movilcontrol/app/services/bluetooth_command_service.dart';
import 'package:movilcontrol/app/services/mock_bluetooth_command_service.dart';

void main() {
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
  });
}
