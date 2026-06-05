import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../data/mappers/car_command_mapper.dart';
import '../../../data/models/auto_state.dart';
import '../../../services/auto_state_polling_service.dart';
import '../../../services/backend_process_service.dart';
import '../../../services/mobile_camera_relay_service.dart';
import 'connection_controller.dart';

class DriveSessionController extends GetxController {
  static const JsonEncoder _statePreviewEncoder = JsonEncoder.withIndent('  ');

  final AutoStatePollingService _pollingService =
      Get.find<AutoStatePollingService>();
  final BackendProcessService _backendProcessService =
      Get.find<BackendProcessService>();
  final MobileCameraRelayService _mobileCameraRelayService =
      Get.find<MobileCameraRelayService>();
  final ConnectionController _connectionController =
      Get.find<ConnectionController>();

  final RxBool isDiagnosticsVisible = false.obs;
  final RxBool isDeveloperModeEnabled = false.obs;
  AutoState? _cachedStatePreviewState;
  String? _cachedStatePreview;

  Rxn<AutoState> get latestState => _pollingService.latestState;
  Rxn<DateTime> get lastPacketAt => _pollingService.lastPacketAt;
  RxString get backendInfoMessage => _backendProcessService.infoMessage;
  RxString get backendRecentLog => _backendProcessService.recentLog;
  Rx<MobileCameraRelayStatus> get mobileCameraStatus =>
      _mobileCameraRelayService.status;
  RxString get mobileCameraInfoMessage => _mobileCameraRelayService.infoMessage;

  AutoState get effectiveState => latestState.value ?? AutoState.initial();
  bool get hasData => latestState.value != null;
  bool get isMobileClient => GetPlatform.isAndroid || GetPlatform.isIOS;
  bool get canUsePhoneCamera => _mobileCameraRelayService.supported;
  bool get isPhoneCameraReady => _mobileCameraRelayService.hasPreview;
  bool get isPhoneCameraStreaming => _mobileCameraRelayService.isStreaming;
  CameraController? get phoneCameraController =>
      _mobileCameraRelayService.controller;
  bool get showPhoneCameraPanel => isMobileClient && canUsePhoneCamera;
  bool get showImmersiveMobileHome => isMobileClient && canUsePhoneCamera;
  bool get isRemotePreviewStreamingEnabled =>
      _pollingService.previewStreamingEnabled;
  bool get canUseDeveloperMode => kDebugMode;
  String get pollingMetricsSummary => _pollingService.metricsSummary;
  String get relayMetricsSummary => _mobileCameraRelayService.metricsSummary;
  String get demoBackendStatusLabel {
    switch (_connectionController.connectionStatus.value) {
      case SocketConnectionStatus.connected:
        return 'Backend conectado';
      case SocketConnectionStatus.connecting:
        return 'Reconectando';
      case SocketConnectionStatus.disconnected:
        return 'Backend desconectado';
    }
  }

  String get demoBackendStatusMessage {
    switch (_connectionController.connectionStatus.value) {
      case SocketConnectionStatus.connected:
        return 'Listo para detectar mano desde la camara del celular.';
      case SocketConnectionStatus.connecting:
        return 'Reconectando con la computadora...';
      case SocketConnectionStatus.disconnected:
        return 'No pudimos hablar con el backend. Verifica que la computadora siga encendida y en la misma red.';
    }
  }

  String get phoneCameraStatusLabel {
    switch (mobileCameraStatus.value) {
      case MobileCameraRelayStatus.unsupported:
        return 'Camara movil no disponible';
      case MobileCameraRelayStatus.idle:
        return 'Camara del celular inactiva';
      case MobileCameraRelayStatus.initializing:
        return 'Abriendo camara del celular';
      case MobileCameraRelayStatus.ready:
        return 'Camara del celular lista';
      case MobileCameraRelayStatus.streaming:
        return 'Camara del celular transmitiendo';
      case MobileCameraRelayStatus.permissionDenied:
        return 'Permiso de camara denegado';
      case MobileCameraRelayStatus.failed:
        return 'Error en la camara del celular';
    }
  }

  String get movementLabel {
    final command = CarCommandMapper.fromAutoState(effectiveState);
    return switch (command) {
      _ when !hasData => 'Auto detenido',
      _ => 'Comando ${CarCommandMapper.toVisualText(command)}',
    };
  }

  String get packetLabel {
    final packetTime = lastPacketAt.value;
    if (packetTime == null) {
      return 'Aun sin datos';
    }

    final hour = packetTime.hour.toString().padLeft(2, '0');
    final minute = packetTime.minute.toString().padLeft(2, '0');
    final second = packetTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  String get handSummary {
    if (!hasData) {
      return 'Esperando estado HTTP del backend Flask.';
    }

    if (!effectiveState.handDetected) {
      return 'No se detecta mano.';
    }

    if (effectiveState.fingerCount <= 0) {
      return 'Mano cerrada';
    }

    if (effectiveState.fingerCount >= 5) {
      return 'Mano abierta';
    }

    if (effectiveState.fingerCount == 1) {
      return '1 dedo detectado';
    }

    return '${effectiveState.fingerCount} dedos detectados';
  }

  String get statePreview {
    final state = effectiveState;
    if (identical(state, _cachedStatePreviewState) &&
        _cachedStatePreview != null) {
      return _cachedStatePreview!;
    }

    final preview = _statePreviewEncoder.convert(state.toJson());
    _cachedStatePreviewState = state;
    _cachedStatePreview = preview;
    return preview;
  }

  String get cameraSummary {
    if (showPhoneCameraPanel && !isRemotePreviewStreamingEnabled) {
      return 'Preview remoto en pausa para mantener fluida la camara del celular. '
          'El backend sigue enviando estado de mano y auto.';
    }

    if (effectiveState.hasCameraPreview) {
      return 'Vista en vivo recibida desde Flask/OpenCV.';
    }

    if (isPhoneCameraStreaming) {
      return 'La camara del celular esta enviando frames al backend. Esperando el primer preview procesado.';
    }

    if (effectiveState.backendMessage.isNotEmpty) {
      return effectiveState.backendMessage;
    }

    if (_connectionController.isConnected) {
      return 'Conectado, esperando el primer frame de la camara.';
    }

    if (backendInfoMessage.value.isNotEmpty) {
      return backendInfoMessage.value;
    }

    if (_connectionController.canAutoStartBackend &&
        _connectionController.isLoopbackHost) {
      return 'Flutter intentara iniciar el backend Flask automaticamente.';
    }

    if (showPhoneCameraPanel && mobileCameraInfoMessage.value.isNotEmpty) {
      return mobileCameraInfoMessage.value;
    }

    return 'La app espera un backend Flask ya disponible en la red.';
  }

  void prepareSessionExperience() {
    _pollingService.setPreviewStreamingEnabled(!isMobileClient);
    if (showImmersiveMobileHome) {
      unawaited(_mobileCameraRelayService.preparePreview());
    }
  }

  Future<void> openDiagnosticsPanel() async {
    isDiagnosticsVisible.value = true;
    _pollingService.setPreviewStreamingEnabled(true);
  }

  Future<void> openControlCenter() async {
    isDiagnosticsVisible.value = true;
  }

  void toggleDeveloperMode() {
    if (!canUseDeveloperMode) {
      return;
    }

    isDeveloperModeEnabled.toggle();
  }

  void closeDiagnosticsPanel() {
    isDiagnosticsVisible.value = false;
    _pollingService.setPreviewStreamingEnabled(!isMobileClient);
  }

  void closeControlCenter() {
    isDiagnosticsVisible.value = false;
  }

  @override
  void onClose() {
    if (canUsePhoneCamera) {
      unawaited(_mobileCameraRelayService.stopRelay(disposeCamera: true));
    }
    super.onClose();
  }
}
