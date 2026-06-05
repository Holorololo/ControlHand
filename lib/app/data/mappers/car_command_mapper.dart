import '../enums/car_command.dart';
import '../models/auto_state.dart';

class CarCommandMapper {
  const CarCommandMapper._();

  static CarCommand fromAutoState(AutoState state) {
    return fromBackendState(
      handDetected: state.handDetected,
      handStatus: state.normalizedHandStatus,
      fingerCount: state.fingerCount,
      backendCommand: state.command,
      payload: state.payload,
    );
  }

  static CarCommand fromBackendState({
    required bool handDetected,
    required String handStatus,
    required int fingerCount,
    String? backendCommand,
    String? payload,
  }) {
    if (!handDetected) {
      return CarCommand.stop;
    }

    final payloadCommand = fromPayload(payload);
    if (payloadCommand != null) {
      return payloadCommand;
    }

    final namedCommand = fromBackendCommand(backendCommand);
    if (namedCommand != null) {
      return namedCommand;
    }

    return fromFingerCount(fingerCount, handStatus: handStatus);
  }

  static CarCommand fromFingerCount(int fingerCount, {String? handStatus}) {
    final normalizedHandStatus = (handStatus ?? '').trim().toLowerCase();
    if (normalizedHandStatus == 'none' ||
        normalizedHandStatus.contains('sin mano') ||
        normalizedHandStatus.contains('no se detecta') ||
        normalizedHandStatus.contains('esperando')) {
      return CarCommand.stop;
    }

    if (normalizedHandStatus.contains('cerrada') ||
        normalizedHandStatus.contains('closed')) {
      return fingerCount <= 0 ? CarCommand.forward : CarCommand.stop;
    }

    if (normalizedHandStatus.contains('abierta') ||
        normalizedHandStatus.contains('open')) {
      return CarCommand.stop;
    }

    return switch (fingerCount) {
      0 => CarCommand.forward,
      1 => CarCommand.left,
      2 => CarCommand.right,
      3 => CarCommand.horn,
      4 => CarCommand.backward,
      5 => CarCommand.stop,
      _ => CarCommand.stop,
    };
  }

  static CarCommand fromHandStatus(String handStatus) {
    final normalized = handStatus.trim().toLowerCase();

    if (normalized.isEmpty ||
        normalized == 'none' ||
        normalized.contains('sin mano') ||
        normalized.contains('no se detecta') ||
        normalized.contains('esperando')) {
      return CarCommand.stop;
    }

    if (normalized.contains('abierta') || normalized.contains('open')) {
      return CarCommand.stop;
    }

    if (normalized.startsWith('4') || normalized.contains('4 dedos')) {
      return CarCommand.backward;
    }

    if (normalized.startsWith('3') || normalized.contains('3 dedos')) {
      return CarCommand.horn;
    }

    if (normalized.startsWith('2') || normalized.contains('2 dedos')) {
      return CarCommand.right;
    }

    if (normalized.startsWith('1') || normalized.contains('1 dedo')) {
      return CarCommand.left;
    }

    if (normalized.contains('cerrada') || normalized.contains('closed')) {
      return CarCommand.forward;
    }

    return CarCommand.stop;
  }

  static CarCommand? fromBackendCommand(String? backendCommand) {
    final normalized = backendCommand?.trim().toLowerCase() ?? '';
    return switch (normalized) {
      'stop' => CarCommand.stop,
      'forward' => CarCommand.forward,
      'backward' => CarCommand.backward,
      'left' => CarCommand.left,
      'right' => CarCommand.right,
      'horn' => CarCommand.horn,
      _ => null,
    };
  }

  static CarCommand? fromPayload(String? payload) {
    final normalized = payload?.trim().toUpperCase() ?? '';
    return switch (normalized) {
      'S' => CarCommand.stop,
      'F' => CarCommand.forward,
      'B' => CarCommand.backward,
      'L' => CarCommand.left,
      'R' => CarCommand.right,
      'H' => CarCommand.horn,
      _ => null,
    };
  }

  static String toPayload(CarCommand command) {
    return switch (command) {
      CarCommand.stop => 'S',
      CarCommand.forward => 'F',
      CarCommand.backward => 'B',
      CarCommand.left => 'L',
      CarCommand.right => 'R',
      CarCommand.horn => 'H',
    };
  }

  static String toVisualText(CarCommand command) {
    return switch (command) {
      CarCommand.stop => 'Parar',
      CarCommand.forward => 'Adelante',
      CarCommand.backward => 'Atras',
      CarCommand.left => 'Izquierda',
      CarCommand.right => 'Derecha',
      CarCommand.horn => 'Bocina',
    };
  }
}
