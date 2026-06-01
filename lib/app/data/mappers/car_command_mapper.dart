import '../enums/car_command.dart';

class CarCommandMapper {
  const CarCommandMapper._();

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
      return CarCommand.forward;
    }

    if (normalized.contains('cerrada') || normalized.contains('closed')) {
      return CarCommand.stop;
    }

    return CarCommand.stop;
  }

  static String toPayload(CarCommand command) {
    return switch (command) {
      CarCommand.forward => 'F',
      CarCommand.stop => 'S',
      CarCommand.left => 'L',
      CarCommand.right => 'R',
      CarCommand.backward => 'B',
    };
  }

  static String toVisualText(CarCommand command) {
    return switch (command) {
      CarCommand.forward => 'Avanzar',
      CarCommand.stop => 'Detener',
      CarCommand.left => 'Izquierda',
      CarCommand.right => 'Derecha',
      CarCommand.backward => 'Retroceder',
    };
  }
}
