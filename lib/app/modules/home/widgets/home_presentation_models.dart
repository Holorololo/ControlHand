import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../data/enums/bluetooth_output_mode.dart';
import 'home_widget_support.dart';

class BluetoothDeviceOptionViewModel {
  const BluetoothDeviceOptionViewModel({
    required this.address,
    required this.name,
    required this.label,
  });

  final String address;
  final String name;
  final String label;
}

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
    required this.previewCacheWidth,
    required this.hasCameraPreview,
    required this.previewBytes,
  });

  factory ProcessedPreviewViewModel({
    required bool handDetected,
    required String cameraSummary,
    required double previewAspectRatio,
    required int? previewCacheWidth,
    required bool hasCameraPreview,
    required Uint8List? previewBytes,
  }) {
    return ProcessedPreviewViewModel._(
      statusLabel: handDetected ? 'Seguimiento activo' : 'Esperando mano',
      statusTone: handDetected ? HomeTone.good : HomeTone.soft,
      cameraSummary: cameraSummary,
      previewAspectRatio: previewAspectRatio,
      previewCacheWidth: previewCacheWidth,
      hasCameraPreview: hasCameraPreview,
      previewBytes: previewBytes,
    );
  }

  final String statusLabel;
  final HomeTone statusTone;
  final String cameraSummary;
  final double previewAspectRatio;
  final int? previewCacheWidth;
  final bool hasCameraPreview;
  final Uint8List? previewBytes;
}

class BluetoothStatusViewModel {
  const BluetoothStatusViewModel._({
    required this.connectionLabel,
    required this.connectionTone,
    required this.transportModeLabel,
    required this.transportModeTone,
    required this.outputModeLabel,
    required this.outputModeTone,
    required this.isBuzzerOutputMode,
    required this.showManualBuzzerControl,
    required this.lastCommandLabel,
    required this.lastPayloadLabel,
    required this.toggleActionLabel,
    required this.connectedDeviceLabel,
    required this.deviceSelectionLabel,
    required this.deviceSelectionHint,
    required this.deviceErrorLabel,
    required this.isLoadingDevices,
    required this.hasPairedDevices,
    required this.selectedDeviceAddress,
    required this.deviceOptions,
    required this.isConnected,
  });

  factory BluetoothStatusViewModel({
    required bool isConnected,
    required bool isMockMode,
    required BluetoothOutputMode outputMode,
    required bool isManualBuzzerControlEnabled,
    required String lastCommandLabel,
    required String lastPayload,
    required String connectedDeviceName,
    required String? connectedDeviceAddress,
    required String selectedDeviceName,
    required String? selectedDeviceAddress,
    required String errorMessage,
    required bool isLoadingDevices,
    required List<BluetoothDeviceOptionViewModel> deviceOptions,
  }) {
    final deviceLabel = _formatBluetoothDeviceLabel(
      name: selectedDeviceName,
      address: selectedDeviceAddress,
      emptyLabel: 'Sin dispositivo',
    );
    final connectedLabel = _formatBluetoothDeviceLabel(
      name: connectedDeviceName,
      address: connectedDeviceAddress,
      emptyLabel: 'Sin conexion activa',
    );

    return BluetoothStatusViewModel._(
      connectionLabel: isConnected
          ? 'Bluetooth conectado'
          : 'Bluetooth desconectado',
      connectionTone: isConnected ? HomeTone.good : HomeTone.alert,
      transportModeLabel: isMockMode
          ? 'Transporte simulado'
          : 'Transporte real',
      transportModeTone: isMockMode ? HomeTone.soft : HomeTone.warn,
      outputModeLabel: outputMode == BluetoothOutputMode.autoVirtual
          ? 'Auto virtual'
          : 'Buzzer real',
      outputModeTone: outputMode == BluetoothOutputMode.autoVirtual
          ? HomeTone.soft
          : HomeTone.good,
      isBuzzerOutputMode: outputMode == BluetoothOutputMode.buzzerReal,
      showManualBuzzerControl:
          outputMode == BluetoothOutputMode.buzzerReal ||
          isManualBuzzerControlEnabled,
      lastCommandLabel: lastCommandLabel.isEmpty
          ? 'Sin comando'
          : lastCommandLabel,
      lastPayloadLabel: lastPayload.isEmpty ? 'Sin payload' : lastPayload,
      toggleActionLabel: isConnected ? 'Desconectar' : 'Conectar',
      connectedDeviceLabel: connectedLabel,
      deviceSelectionLabel: deviceLabel,
      deviceSelectionHint: deviceOptions.isEmpty
          ? 'No hay dispositivos emparejados.'
          : 'Selecciona un HC-05/HC-06 emparejado antes de conectar.',
      deviceErrorLabel: errorMessage,
      isLoadingDevices: isLoadingDevices,
      hasPairedDevices: deviceOptions.isNotEmpty,
      selectedDeviceAddress: selectedDeviceAddress,
      deviceOptions: deviceOptions,
      isConnected: isConnected,
    );
  }

  final String connectionLabel;
  final HomeTone connectionTone;
  final String transportModeLabel;
  final HomeTone transportModeTone;
  final String outputModeLabel;
  final HomeTone outputModeTone;
  final bool isBuzzerOutputMode;
  final bool showManualBuzzerControl;
  final String lastCommandLabel;
  final String lastPayloadLabel;
  final String toggleActionLabel;
  final String connectedDeviceLabel;
  final String deviceSelectionLabel;
  final String deviceSelectionHint;
  final String deviceErrorLabel;
  final bool isLoadingDevices;
  final bool hasPairedDevices;
  final String? selectedDeviceAddress;
  final List<BluetoothDeviceOptionViewModel> deviceOptions;
  final bool isConnected;
}

String _formatBluetoothDeviceLabel({
  required String name,
  required String? address,
  required String emptyLabel,
}) {
  final normalizedName = name.trim();
  final normalizedAddress = address?.trim() ?? '';

  if (normalizedName.isNotEmpty && normalizedAddress.isNotEmpty) {
    return '$normalizedName ($normalizedAddress)';
  }
  if (normalizedName.isNotEmpty) {
    return normalizedName;
  }
  if (normalizedAddress.isNotEmpty) {
    return normalizedAddress;
  }
  return emptyLabel;
}
