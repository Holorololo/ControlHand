import '../enums/hand_gesture_type.dart';
import '../enums/vehicle_motion_state.dart';

class BackendSnapshotDto {
  const BackendSnapshotDto({
    required this.timestamp,
    required this.handDetected,
    required this.handState,
    required this.fingersUp,
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
    final handState = (json['hand_state'] as String?) ?? 'Sin estado';
    final carMoving = json['car_moving'] == true;
    final timestampSeconds = (json['timestamp'] as num?)?.toDouble() ?? 0;
    final milliseconds = (timestampSeconds * 1000).round();

    return BackendSnapshotDto(
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
        isUtc: true,
      ).toLocal(),
      handDetected: json['hand_detected'] == true,
      handState: handState,
      fingersUp: (json['fingers_up'] as num?)?.toInt() ?? 0,
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
      handGestureType: _mapHandGestureType(handState),
      vehicleMotionState: carMoving
          ? VehicleMotionState.moving
          : VehicleMotionState.stopped,
    );
  }

  final DateTime timestamp;
  final bool handDetected;
  final String handState;
  final int fingersUp;
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

HandGestureType _mapHandGestureType(String handState) {
  final normalizedState = handState.trim().toUpperCase();

  if (normalizedState.contains('ABIERTA')) {
    return HandGestureType.open;
  }

  if (normalizedState.contains('CERRADA')) {
    return HandGestureType.closed;
  }

  if (normalizedState.contains('NO SE DETECTA') ||
      normalizedState.contains('ESPERANDO')) {
    return HandGestureType.none;
  }

  return HandGestureType.unknown;
}
