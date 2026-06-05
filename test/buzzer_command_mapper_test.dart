import 'package:flutter_test/flutter_test.dart';

import 'package:movilcontrol/app/data/enums/buzzer_command.dart';
import 'package:movilcontrol/app/data/mappers/buzzer_command_mapper.dart';

void main() {
  group('BuzzerCommandMapper', () {
    test('maps closed hand to buzzer on and payload 1', () {
      final command = BuzzerCommandMapper.fromHandStatus('MANO CERRADA');

      expect(command, BuzzerCommand.on);
      expect(BuzzerCommandMapper.toPayload(command), '1');
      expect(BuzzerCommandMapper.toVisualText(command), 'Encender buzzer');
    });

    test('maps open hand to buzzer off and payload 0', () {
      final command = BuzzerCommandMapper.fromHandStatus('MANO ABIERTA');

      expect(command, BuzzerCommand.off);
      expect(BuzzerCommandMapper.toPayload(command), '0');
      expect(BuzzerCommandMapper.toVisualText(command), 'Apagar buzzer');
    });

    test('maps no hand to buzzer off and payload 0', () {
      final command = BuzzerCommandMapper.fromHandStatus('none');

      expect(command, BuzzerCommand.off);
      expect(BuzzerCommandMapper.toPayload(command), '0');
    });
  });
}
