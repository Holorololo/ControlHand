import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'home_widget_support.dart';

class ConnectionStatusViewModel {
  const ConnectionStatusViewModel._({
    required this.statusLabel,
    required this.statusTone,
    required this.intro,
    required this.hostHelperText,
    required this.portHelperText,
    required this.phoneCameraStatusLabel,
    required this.phoneCameraTone,
    required this.backendStatusLabel,
    required this.backendStatusTone,
    required this.endpointLabel,
    required this.connectionHint,
    required this.backendActionHint,
    required this.isConnecting,
    required this.isConnected,
    required this.canRestartManagedBackend,
    required this.primaryActionLabel,
    required this.primaryActionIcon,
  });

  factory ConnectionStatusViewModel({
    required String statusLabel,
    required HomeTone statusTone,
    required String intro,
    required bool isMobileClient,
    required String phoneCameraStatusLabel,
    required HomeTone phoneCameraTone,
    required String backendStatusLabel,
    required HomeTone backendStatusTone,
    required String endpointLabel,
    required String connectionHint,
    required String backendActionHint,
    required bool isConnecting,
    required bool isConnected,
    required bool canRestartManagedBackend,
  }) {
    return ConnectionStatusViewModel._(
      statusLabel: statusLabel,
      statusTone: statusTone,
      intro: intro,
      hostHelperText: isMobileClient
          ? 'Usa la IP LAN de tu PC o adb reverse'
          : '127.0.0.1 usa tu backend local',
      portHelperText: 'El backend remoto escucha en 5000 por defecto',
      phoneCameraStatusLabel: phoneCameraStatusLabel,
      phoneCameraTone: phoneCameraTone,
      backendStatusLabel: backendStatusLabel,
      backendStatusTone: backendStatusTone,
      endpointLabel: endpointLabel,
      connectionHint: connectionHint,
      backendActionHint: backendActionHint,
      isConnecting: isConnecting,
      isConnected: isConnected,
      canRestartManagedBackend: canRestartManagedBackend,
      primaryActionLabel: isConnected ? 'Desconectar' : 'Conectar',
      primaryActionIcon: isConnected
          ? Icons.link_off_rounded
          : Icons.wifi_tethering_rounded,
    );
  }

  final String statusLabel;
  final HomeTone statusTone;
  final String intro;
  final String hostHelperText;
  final String portHelperText;
  final String phoneCameraStatusLabel;
  final HomeTone phoneCameraTone;
  final String backendStatusLabel;
  final HomeTone backendStatusTone;
  final String endpointLabel;
  final String connectionHint;
  final String backendActionHint;
  final bool isConnecting;
  final bool isConnected;
  final bool canRestartManagedBackend;
  final String primaryActionLabel;
  final IconData primaryActionIcon;
}

class BackendStatusViewModel {
  const BackendStatusViewModel._({
    required this.command,
    required this.recentLogMessage,
    required this.statePreview,
  });

  factory BackendStatusViewModel({
    required String command,
    required String recentLog,
    required String infoMessage,
    required String statePreview,
  }) {
    return BackendStatusViewModel._(
      command: command,
      recentLogMessage: recentLog.isEmpty
          ? (infoMessage.isEmpty
                ? 'Sin eventos recientes del proceso Python.'
                : infoMessage)
          : recentLog,
      statePreview: statePreview,
    );
  }

  final String command;
  final String recentLogMessage;
  final String statePreview;
}

class HandStatusViewModel {
  const HandStatusViewModel._({
    required this.summary,
    required this.cameraStatusLabel,
    required this.cameraTone,
    required this.detailMessage,
    required this.fingersValue,
    required this.carValue,
    required this.packetLabel,
  });

  factory HandStatusViewModel({
    required String summary,
    required String cameraStatusLabel,
    required HomeTone cameraTone,
    required String cameraSummary,
    required String mobileCameraInfoMessage,
    required int fingersUp,
    required bool carMoving,
    required String packetLabel,
  }) {
    return HandStatusViewModel._(
      summary: summary,
      cameraStatusLabel: cameraStatusLabel,
      cameraTone: cameraTone,
      detailMessage: mobileCameraInfoMessage.isEmpty
          ? cameraSummary
          : mobileCameraInfoMessage,
      fingersValue: '$fingersUp',
      carValue: carMoving ? 'AVANZA' : 'STOP',
      packetLabel: packetLabel,
    );
  }

  final String summary;
  final String cameraStatusLabel;
  final HomeTone cameraTone;
  final String detailMessage;
  final String fingersValue;
  final String carValue;
  final String packetLabel;
}

class CarStatusViewModel {
  const CarStatusViewModel._({
    required this.movementLabel,
    required this.statusLabel,
    required this.statusTone,
    required this.fingersValue,
    required this.speedValue,
    required this.handStateLabel,
    required this.carProgress,
    required this.isMoving,
    required this.errorMessage,
  });

  factory CarStatusViewModel({
    required String movementLabel,
    required bool carMoving,
    required int fingersUp,
    required int speed,
    required String handState,
    required double carProgress,
    required String errorMessage,
  }) {
    return CarStatusViewModel._(
      movementLabel: movementLabel,
      statusLabel: carMoving ? 'GO' : 'STOP',
      statusTone: carMoving ? HomeTone.good : HomeTone.alert,
      fingersValue: '$fingersUp',
      speedValue: '$speed',
      handStateLabel: handState,
      carProgress: carProgress,
      isMoving: carMoving,
      errorMessage: errorMessage,
    );
  }

  final String movementLabel;
  final String statusLabel;
  final HomeTone statusTone;
  final String fingersValue;
  final String speedValue;
  final String handStateLabel;
  final double carProgress;
  final bool isMoving;
  final String errorMessage;
}

class ProcessedPreviewViewModel {
  const ProcessedPreviewViewModel._({
    required this.statusLabel,
    required this.statusTone,
    required this.cameraSummary,
    required this.previewAspectRatio,
    required this.hasCameraPreview,
    required this.previewBytes,
  });

  factory ProcessedPreviewViewModel({
    required bool handDetected,
    required String cameraSummary,
    required double previewAspectRatio,
    required bool hasCameraPreview,
    required Uint8List? previewBytes,
  }) {
    return ProcessedPreviewViewModel._(
      statusLabel: handDetected ? 'Seguimiento activo' : 'Esperando mano',
      statusTone: handDetected ? HomeTone.good : HomeTone.soft,
      cameraSummary: cameraSummary,
      previewAspectRatio: previewAspectRatio,
      hasCameraPreview: hasCameraPreview,
      previewBytes: previewBytes,
    );
  }

  final String statusLabel;
  final HomeTone statusTone;
  final String cameraSummary;
  final double previewAspectRatio;
  final bool hasCameraPreview;
  final Uint8List? previewBytes;
}
