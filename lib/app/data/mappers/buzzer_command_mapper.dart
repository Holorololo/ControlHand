import '../enums/buzzer_command.dart';
import '../enums/hand_gesture_type.dart';

class BuzzerCommandMapper {
  const BuzzerCommandMapper._();

  static BuzzerCommand fromGestureType(HandGestureType gestureType) {
    return switch (gestureType) {
      HandGestureType.closed => BuzzerCommand.on,
      HandGestureType.open => BuzzerCommand.off,
      HandGestureType.none => BuzzerCommand.off,
      HandGestureType.unknown => BuzzerCommand.off,
    };
  }

  static BuzzerCommand fromHandStatus(String handStatus) {
    final normalized = handStatus.trim().toLowerCase();

    if (normalized.contains('cerrada') || normalized.contains('closed')) {
      return BuzzerCommand.on;
    }

    if (normalized.isEmpty ||
        normalized == 'none' ||
        normalized.contains('abierta') ||
        normalized.contains('open') ||
        normalized.contains('sin mano') ||
        normalized.contains('no se detecta') ||
        normalized.contains('esperando')) {
      return BuzzerCommand.off;
    }

    return BuzzerCommand.off;
  }

  static String toPayload(BuzzerCommand command) {
    return switch (command) {
      BuzzerCommand.on => '1',
      BuzzerCommand.off => '0',
    };
  }

  static String toVisualText(BuzzerCommand command) {
    return switch (command) {
      BuzzerCommand.on => 'Encender buzzer',
      BuzzerCommand.off => 'Apagar buzzer',
    };
  }
}
