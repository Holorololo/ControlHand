import 'package:flutter_test/flutter_test.dart';

import 'package:movilcontrol/app/data/enums/car_command.dart';
import 'package:movilcontrol/app/modules/home/controllers/bluetooth_controller.dart';
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
  });
}
