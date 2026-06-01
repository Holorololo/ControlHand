import 'package:flutter_test/flutter_test.dart';

import 'package:movilcontrol/app/data/enums/car_command.dart';
import 'package:movilcontrol/app/data/mappers/car_command_mapper.dart';

void main() {
  group('CarCommandMapper', () {
    test('maps open hand to forward and payload F', () {
      final command = CarCommandMapper.fromHandStatus('MANO ABIERTA');

      expect(command, CarCommand.forward);
      expect(CarCommandMapper.toPayload(command), 'F');
      expect(CarCommandMapper.toVisualText(command), 'Avanzar');
    });

    test('maps closed hand to stop and payload S', () {
      final command = CarCommandMapper.fromHandStatus('MANO CERRADA');

      expect(command, CarCommand.stop);
      expect(CarCommandMapper.toPayload(command), 'S');
      expect(CarCommandMapper.toVisualText(command), 'Detener');
    });
  });
}
