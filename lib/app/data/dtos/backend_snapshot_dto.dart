import '../enums/hand_gesture_type.dart';
import '../enums/vehicle_motion_state.dart';

class BackendSnapshotDto {
  const BackendSnapshotDto({
    required this.timestamp,
    required this.handDetected,
    required this.handStatus,
    required this.handState,
    required this.fingerCount,
    required this.fingersUp,
    required this.command,
    required this.payload,
    required this.carMoving,
    required this.carX,
    required this.carY,
    required this.speed,
    required this.backendReady,
    required this.backendSource,
    required this.backendMessage,
    required this.backendLastError,
    required this.cameraPreviewAvailable,
    required this.cameraPreviewWidth,
    required this.cameraPreviewHeight,
    required this.cameraPreviewVersion,
    required this.handGestureType,
    required this.vehicleMotionState,
  });

  factory BackendSnapshotDto.fromJson(Map<String, dynamic> json) {
    final handStatus =
        (json['hand_status'] as String?) ??
        (json['handStatus'] as String?) ??
        'none';
    final fingerCount =
        (json['finger_count'] as num?)?.toInt() ??
        (json['fingerCount'] as num?)?.toInt() ??
        (json['fingers_up'] as num?)?.toInt() ??
        0;
    final handState =
        (json['hand_state'] as String?) ??
        _buildHandStateLabel(
          handStatus: handStatus,
          fingerCount: fingerCount,
          handDetected: json['hand_detected'] == true,
        );
    final command =
        (json['command'] as String?) ?? _commandFromFingerCount(fingerCount);
    final payload =
        (json['payload'] as String?) ?? _payloadFromCommand(command) ?? 'S';
    final carMoving = json['car_moving'] == true;
    final timestampSeconds = (json['timestamp'] as num?)?.toDouble() ?? 0;
    final milliseconds = (timestampSeconds * 1000).round();

    return BackendSnapshotDto(
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
        isUtc: true,
      ).toLocal(),
      handDetected: json['hand_detected'] == true,
      handStatus: handStatus,
      handState: handState,
      fingerCount: fingerCount,
      fingersUp: fingerCount,
      command: command,
      payload: payload,
      carMoving: carMoving,
      carX: (json['car_x'] as num?)?.toDouble() ?? 50,
      carY: (json['car_y'] as num?)?.toDouble() ?? 350,
      speed: (json['speed'] as num?)?.toInt() ?? 0,
      backendReady: json['backend_ready'] == true,
      backendSource: (json['backend_source'] as String?) ?? '',
      backendMessage: (json['backend_message'] as String?) ?? '',
      backendLastError: (json['backend_last_error'] as String?) ?? '',
      cameraPreviewAvailable: json['camera_preview_available'] == true,
      cameraPreviewWidth: (json['camera_preview_width'] as num?)?.toInt(),
      cameraPreviewHeight: (json['camera_preview_height'] as num?)?.toInt(),
      cameraPreviewVersion: (json['camera_preview_version'] as num?)?.toInt(),
      handGestureType: _mapHandGestureType(handStatus),
      vehicleMotionState: carMoving
          ? VehicleMotionState.moving
          : VehicleMotionState.stopped,
    );
  }

  final DateTime timestamp;
  final bool handDetected;
  final String handStatus;
  final String handState;
  final int fingerCount;
  final int fingersUp;
  final String command;
  final String payload;
  final bool carMoving;
  final double carX;
  final double carY;
  final int speed;
  final bool backendReady;
  final String backendSource;
  final String backendMessage;
  final String backendLastError;
  final bool cameraPreviewAvailable;
  final int? cameraPreviewWidth;
  final int? cameraPreviewHeight;
  final int? cameraPreviewVersion;
  final HandGestureType handGestureType;
  final VehicleMotionState vehicleMotionState;
}

HandGestureType _mapHandGestureType(String handStatus) {
  final normalizedState = handStatus.trim().toUpperCase();

  if (normalizedState.contains('OPEN') || normalizedState.contains('ABIERTA')) {
    return HandGestureType.open;
  }

  if (normalizedState.contains('CLOSED') ||
      normalizedState.contains('CERRADA')) {
    return HandGestureType.closed;
  }

  if (normalizedState.contains('NONE') ||
      normalizedState.contains('NO SE DETECTA') ||
      normalizedState.contains('ESPERANDO')) {
    return HandGestureType.none;
  }

  return HandGestureType.unknown;
}

String _buildHandStateLabel({
  required String handStatus,
  required int fingerCount,
  required bool handDetected,
}) {
  if (!handDetected || handStatus == 'none') {
    return 'SIN MANO';
  }

  if (handStatus == 'closed' || fingerCount <= 0) {
    return 'MANO CERRADA';
  }

  if (handStatus == 'open' || fingerCount >= 5) {
    return 'MANO ABIERTA';
  }

  if (fingerCount == 1) {
    return '1 DEDO';
  }

  return '$fingerCount DEDOS';
}

String _commandFromFingerCount(int fingerCount) {
  return switch (fingerCount) {
    0 => 'stop',
    1 => 'left',
    2 => 'right',
    3 => 'horn',
    4 => 'backward',
    5 => 'forward',
    _ => 'stop',
  };
}

String? _payloadFromCommand(String command) {
  return switch (command.trim().toLowerCase()) {
    'stop' => 'S',
    'left' => 'L',
    'right' => 'R',
    'horn' => 'H',
    'backward' => 'B',
    'forward' => 'F',
    _ => null,
  };
}
