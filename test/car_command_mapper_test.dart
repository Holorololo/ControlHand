import 'package:flutter_test/flutter_test.dart';

import 'package:movilcontrol/app/data/enums/car_command.dart';
import 'package:movilcontrol/app/data/mappers/car_command_mapper.dart';

void main() {
  group('CarCommandMapper', () {
    test('maps 0 fingers to stop and payload S', () {
      final command = CarCommandMapper.fromFingerCount(0, handStatus: 'closed');

      expect(command, CarCommand.stop);
      expect(CarCommandMapper.toPayload(command), 'S');
      expect(CarCommandMapper.toVisualText(command), 'Parar');
    });

    test('maps 1 finger to left and payload L', () {
      final command = CarCommandMapper.fromFingerCount(
        1,
        handStatus: 'partial',
      );

      expect(command, CarCommand.left);
      expect(CarCommandMapper.toPayload(command), 'L');
      expect(CarCommandMapper.toVisualText(command), 'Izquierda');
    });

    test('maps 2 fingers to right and payload R', () {
      final command = CarCommandMapper.fromFingerCount(
        2,
        handStatus: 'partial',
      );

      expect(command, CarCommand.right);
      expect(CarCommandMapper.toPayload(command), 'R');
      expect(CarCommandMapper.toVisualText(command), 'Derecha');
    });

    test('maps 3 fingers to horn and payload H', () {
      final command = CarCommandMapper.fromFingerCount(
        3,
        handStatus: 'partial',
      );

      expect(command, CarCommand.horn);
      expect(CarCommandMapper.toPayload(command), 'H');
      expect(CarCommandMapper.toVisualText(command), 'Bocina');
    });

    test('maps 4 fingers to backward and payload B', () {
      final command = CarCommandMapper.fromFingerCount(
        4,
        handStatus: 'partial',
      );

      expect(command, CarCommand.backward);
      expect(CarCommandMapper.toPayload(command), 'B');
      expect(CarCommandMapper.toVisualText(command), 'Atras');
    });

    test('maps 5 fingers to forward and payload F', () {
      final command = CarCommandMapper.fromFingerCount(5, handStatus: 'open');

      expect(command, CarCommand.forward);
      expect(CarCommandMapper.toPayload(command), 'F');
      expect(CarCommandMapper.toVisualText(command), 'Adelante');
    });

    test('maps no hand to stop and payload S', () {
      final command = CarCommandMapper.fromBackendState(
        handDetected: false,
        handStatus: 'none',
        fingerCount: 0,
      );

      expect(command, CarCommand.stop);
      expect(CarCommandMapper.toPayload(command), 'S');
    });
  });
}
