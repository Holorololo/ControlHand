import 'dart:typed_data';

import '../dtos/backend_snapshot_dto.dart';

class AutoState {
  const AutoState({
    required this.timestamp,
    required this.handDetected,
    required this.handState,
    required this.fingersUp,
    required this.carMoving,
    required this.carX,
    required this.carY,
    required this.speed,
    required this.backendReady,
    required this.backendMessage,
    required this.backendLastError,
    this.previewBytes,
    this.cameraFrameWidth,
    this.cameraFrameHeight,
  });

  factory AutoState.initial() {
    return AutoState(
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      handDetected: false,
      handState: 'Esperando backend',
      fingersUp: 0,
      carMoving: false,
      carX: 50,
      carY: 350,
      speed: 8,
      backendReady: false,
      backendMessage: 'Esperando backend',
      backendLastError: '',
      previewBytes: null,
      cameraFrameWidth: null,
      cameraFrameHeight: null,
    );
  }

  factory AutoState.fromJson(
    Map<String, dynamic> json, {
    Uint8List? previewBytes,
    int? previewWidth,
    int? previewHeight,
  }) {
    return AutoState.fromSnapshotDto(
      BackendSnapshotDto.fromJson(json),
      previewBytes: previewBytes,
      previewWidth: previewWidth,
      previewHeight: previewHeight,
    );
  }

  factory AutoState.fromSnapshotDto(
    BackendSnapshotDto snapshot, {
    Uint8List? previewBytes,
    int? previewWidth,
    int? previewHeight,
  }) {
    return AutoState(
      timestamp: snapshot.timestamp,
      handDetected: snapshot.handDetected,
      handState: snapshot.handState,
      fingersUp: snapshot.fingersUp,
      carMoving: snapshot.carMoving,
      carX: snapshot.carX,
      carY: snapshot.carY,
      speed: snapshot.speed,
      backendReady: snapshot.backendReady,
      backendMessage: snapshot.backendMessage,
      backendLastError: snapshot.backendLastError,
      previewBytes: previewBytes,
      cameraFrameWidth: previewWidth ?? snapshot.cameraPreviewWidth,
      cameraFrameHeight: previewHeight ?? snapshot.cameraPreviewHeight,
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
  final String backendMessage;
  final String backendLastError;
  final Uint8List? previewBytes;
  final int? cameraFrameWidth;
  final int? cameraFrameHeight;

  AutoState copyWith({
    DateTime? timestamp,
    bool? handDetected,
    String? handState,
    int? fingersUp,
    bool? carMoving,
    double? carX,
    double? carY,
    int? speed,
    bool? backendReady,
    String? backendMessage,
    String? backendLastError,
    Uint8List? previewBytes,
    int? cameraFrameWidth,
    int? cameraFrameHeight,
    bool clearPreview = false,
  }) {
    return AutoState(
      timestamp: timestamp ?? this.timestamp,
      handDetected: handDetected ?? this.handDetected,
      handState: handState ?? this.handState,
      fingersUp: fingersUp ?? this.fingersUp,
      carMoving: carMoving ?? this.carMoving,
      carX: carX ?? this.carX,
      carY: carY ?? this.carY,
      speed: speed ?? this.speed,
      backendReady: backendReady ?? this.backendReady,
      backendMessage: backendMessage ?? this.backendMessage,
      backendLastError: backendLastError ?? this.backendLastError,
      previewBytes: clearPreview ? null : (previewBytes ?? this.previewBytes),
      cameraFrameWidth: clearPreview
          ? null
          : (cameraFrameWidth ?? this.cameraFrameWidth),
      cameraFrameHeight: clearPreview
          ? null
          : (cameraFrameHeight ?? this.cameraFrameHeight),
    );
  }

  static const double backendTrackWidth = 900;
  static const double backendCarWidth = 120;

  bool get hasCameraPreview => previewBytes != null && previewBytes!.isNotEmpty;

  double get previewAspectRatio {
    final width = cameraFrameWidth;
    final height = cameraFrameHeight;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return 4 / 3;
    }
    return width / height;
  }

  double get carProgress {
    final totalTravel = backendTrackWidth + backendCarWidth;
    final normalized = (carX + backendCarWidth) / totalTravel;
    return normalized.clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'timestamp': timestamp.toIso8601String(),
      'hand_detected': handDetected,
      'hand_state': handState,
      'fingers_up': fingersUp,
      'car_moving': carMoving,
      'car_x': carX,
      'car_y': carY,
      'speed': speed,
      'backend_ready': backendReady,
      'backend_message': backendMessage,
      'backend_last_error': backendLastError,
      'camera_preview_available': hasCameraPreview,
      'camera_preview_width': cameraFrameWidth,
      'camera_preview_height': cameraFrameHeight,
    };
  }
}
