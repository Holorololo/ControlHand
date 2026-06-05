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
    this.handLabel = '',
    this.rawFingerCount = 0,
    this.stableFingerCount = 0,
    this.rawHandStatus = 'none',
    this.rawCommand = 'stop',
    this.rawPayload = 'S',
    this.rawFingers = const <String, bool>{},
    this.stabilityFramesRequired = 0,
    this.stabilityMatchCount = 0,
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
    final handDetected = json['hand_detected'] == true;
    final command =
        (json['command'] as String?) ??
        _commandFromDetection(
          handStatus: handStatus,
          fingerCount: fingerCount,
          handDetected: handDetected,
        );
    final payload =
        (json['payload'] as String?) ?? _payloadFromCommand(command) ?? 'S';
    final carMoving = json['car_moving'] == true;
    final timestampSeconds = (json['timestamp'] as num?)?.toDouble() ?? 0;
    final milliseconds = (timestampSeconds * 1000).round();
    final rawFingersJson = json['raw_fingers'];

    return BackendSnapshotDto(
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
        isUtc: true,
      ).toLocal(),
      handDetected: handDetected,
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
      handLabel: (json['hand_label'] as String?) ?? '',
      rawFingerCount:
          (json['raw_finger_count'] as num?)?.toInt() ?? fingerCount,
      stableFingerCount:
          (json['stable_finger_count'] as num?)?.toInt() ?? fingerCount,
      rawHandStatus: (json['raw_hand_status'] as String?) ?? handStatus,
      rawCommand: (json['raw_command'] as String?) ?? command,
      rawPayload: (json['raw_payload'] as String?) ?? payload,
      rawFingers: rawFingersJson is Map
          ? rawFingersJson.map(
              (key, value) => MapEntry(key.toString(), value == true),
            )
          : const <String, bool>{},
      stabilityFramesRequired:
          (json['stability_frames_required'] as num?)?.toInt() ?? 0,
      stabilityMatchCount:
          (json['stability_match_count'] as num?)?.toInt() ?? 0,
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
  final String handLabel;
  final int rawFingerCount;
  final int stableFingerCount;
  final String rawHandStatus;
  final String rawCommand;
  final String rawPayload;
  final Map<String, bool> rawFingers;
  final int stabilityFramesRequired;
  final int stabilityMatchCount;
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

String _commandFromDetection({
  required String handStatus,
  required int fingerCount,
  required bool handDetected,
}) {
  if (!handDetected || handStatus == 'none') {
    return 'stop';
  }

  if (handStatus == 'closed' && fingerCount <= 0) {
    return 'forward';
  }

  return switch (fingerCount) {
    0 => 'forward',
    1 => 'left',
    2 => 'right',
    3 => 'horn',
    4 => 'backward',
    5 => 'stop',
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
