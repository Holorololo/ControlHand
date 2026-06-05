import 'dart:typed_data';

import '../dtos/backend_snapshot_dto.dart';

class AutoState {
  const AutoState({
    required this.timestamp,
    required this.handDetected,
    this.normalizedHandStatus = 'none',
    required this.handState,
    required this.fingersUp,
    this.command = 'stop',
    this.payload = 'S',
    required this.carMoving,
    required this.carX,
    required this.carY,
    required this.speed,
    required this.backendReady,
    required this.backendMessage,
    required this.backendLastError,
    this.previewBytes,
    this.previewVersion,
    this.cameraFrameWidth,
    this.cameraFrameHeight,
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

  factory AutoState.initial() {
    return AutoState(
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      handDetected: false,
      normalizedHandStatus: 'none',
      handState: 'Esperando backend',
      fingersUp: 0,
      command: 'stop',
      payload: 'S',
      carMoving: false,
      carX: 50,
      carY: 350,
      speed: 8,
      backendReady: false,
      backendMessage: 'Esperando backend',
      backendLastError: '',
      previewBytes: null,
      previewVersion: null,
      cameraFrameWidth: null,
      cameraFrameHeight: null,
      handLabel: '',
      rawFingerCount: 0,
      stableFingerCount: 0,
      rawHandStatus: 'none',
      rawCommand: 'stop',
      rawPayload: 'S',
      rawFingers: const <String, bool>{},
      stabilityFramesRequired: 0,
      stabilityMatchCount: 0,
    );
  }

  factory AutoState.fromJson(
    Map<String, dynamic> json, {
    Uint8List? previewBytes,
    int? previewVersion,
    int? previewWidth,
    int? previewHeight,
  }) {
    return AutoState.fromSnapshotDto(
      BackendSnapshotDto.fromJson(json),
      previewBytes: previewBytes,
      previewVersion: previewVersion,
      previewWidth: previewWidth,
      previewHeight: previewHeight,
    );
  }

  factory AutoState.fromSnapshotDto(
    BackendSnapshotDto snapshot, {
    Uint8List? previewBytes,
    int? previewVersion,
    int? previewWidth,
    int? previewHeight,
  }) {
    return AutoState(
      timestamp: snapshot.timestamp,
      handDetected: snapshot.handDetected,
      normalizedHandStatus: snapshot.handStatus,
      handState: snapshot.handState,
      fingersUp: snapshot.fingerCount,
      command: snapshot.command,
      payload: snapshot.payload,
      carMoving: snapshot.carMoving,
      carX: snapshot.carX,
      carY: snapshot.carY,
      speed: snapshot.speed,
      backendReady: snapshot.backendReady,
      backendMessage: snapshot.backendMessage,
      backendLastError: snapshot.backendLastError,
      previewBytes: previewBytes,
      previewVersion: previewVersion ?? snapshot.cameraPreviewVersion,
      cameraFrameWidth: previewWidth ?? snapshot.cameraPreviewWidth,
      cameraFrameHeight: previewHeight ?? snapshot.cameraPreviewHeight,
      handLabel: snapshot.handLabel,
      rawFingerCount: snapshot.rawFingerCount,
      stableFingerCount: snapshot.stableFingerCount,
      rawHandStatus: snapshot.rawHandStatus,
      rawCommand: snapshot.rawCommand,
      rawPayload: snapshot.rawPayload,
      rawFingers: snapshot.rawFingers,
      stabilityFramesRequired: snapshot.stabilityFramesRequired,
      stabilityMatchCount: snapshot.stabilityMatchCount,
    );
  }

  final DateTime timestamp;
  final bool handDetected;
  final String normalizedHandStatus;
  final String handState;
  final int fingersUp;
  final String command;
  final String payload;
  final bool carMoving;
  final double carX;
  final double carY;
  final int speed;
  final bool backendReady;
  final String backendMessage;
  final String backendLastError;
  final Uint8List? previewBytes;
  final int? previewVersion;
  final int? cameraFrameWidth;
  final int? cameraFrameHeight;
  final String handLabel;
  final int rawFingerCount;
  final int stableFingerCount;
  final String rawHandStatus;
  final String rawCommand;
  final String rawPayload;
  final Map<String, bool> rawFingers;
  final int stabilityFramesRequired;
  final int stabilityMatchCount;

  int get fingerCount => fingersUp;

  AutoState copyWith({
    DateTime? timestamp,
    bool? handDetected,
    String? normalizedHandStatus,
    String? handState,
    int? fingersUp,
    String? command,
    String? payload,
    bool? carMoving,
    double? carX,
    double? carY,
    int? speed,
    bool? backendReady,
    String? backendMessage,
    String? backendLastError,
    Uint8List? previewBytes,
    int? previewVersion,
    int? cameraFrameWidth,
    int? cameraFrameHeight,
    String? handLabel,
    int? rawFingerCount,
    int? stableFingerCount,
    String? rawHandStatus,
    String? rawCommand,
    String? rawPayload,
    Map<String, bool>? rawFingers,
    int? stabilityFramesRequired,
    int? stabilityMatchCount,
    bool clearPreview = false,
  }) {
    return AutoState(
      timestamp: timestamp ?? this.timestamp,
      handDetected: handDetected ?? this.handDetected,
      normalizedHandStatus: normalizedHandStatus ?? this.normalizedHandStatus,
      handState: handState ?? this.handState,
      fingersUp: fingersUp ?? this.fingersUp,
      command: command ?? this.command,
      payload: payload ?? this.payload,
      carMoving: carMoving ?? this.carMoving,
      carX: carX ?? this.carX,
      carY: carY ?? this.carY,
      speed: speed ?? this.speed,
      backendReady: backendReady ?? this.backendReady,
      backendMessage: backendMessage ?? this.backendMessage,
      backendLastError: backendLastError ?? this.backendLastError,
      previewBytes: clearPreview ? null : (previewBytes ?? this.previewBytes),
      previewVersion: clearPreview
          ? null
          : (previewVersion ?? this.previewVersion),
      cameraFrameWidth: clearPreview
          ? null
          : (cameraFrameWidth ?? this.cameraFrameWidth),
      cameraFrameHeight: clearPreview
          ? null
          : (cameraFrameHeight ?? this.cameraFrameHeight),
      handLabel: handLabel ?? this.handLabel,
      rawFingerCount: rawFingerCount ?? this.rawFingerCount,
      stableFingerCount: stableFingerCount ?? this.stableFingerCount,
      rawHandStatus: rawHandStatus ?? this.rawHandStatus,
      rawCommand: rawCommand ?? this.rawCommand,
      rawPayload: rawPayload ?? this.rawPayload,
      rawFingers: rawFingers ?? this.rawFingers,
      stabilityFramesRequired:
          stabilityFramesRequired ?? this.stabilityFramesRequired,
      stabilityMatchCount: stabilityMatchCount ?? this.stabilityMatchCount,
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
      'hand_status': normalizedHandStatus,
      'hand_state': handState,
      'finger_count': fingerCount,
      'fingers_up': fingersUp,
      'command': command,
      'payload': payload,
      'car_moving': carMoving,
      'car_x': carX,
      'car_y': carY,
      'speed': speed,
      'backend_ready': backendReady,
      'backend_message': backendMessage,
      'backend_last_error': backendLastError,
      'camera_preview_available': hasCameraPreview,
      'camera_preview_version': previewVersion,
      'camera_preview_width': cameraFrameWidth,
      'camera_preview_height': cameraFrameHeight,
      'hand_label': handLabel,
      'raw_finger_count': rawFingerCount,
      'stable_finger_count': stableFingerCount,
      'raw_hand_status': rawHandStatus,
      'raw_command': rawCommand,
      'raw_payload': rawPayload,
      'raw_fingers': rawFingers,
      'stability_frames_required': stabilityFramesRequired,
      'stability_match_count': stabilityMatchCount,
    };
  }
}
