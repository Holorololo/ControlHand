import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:get/get.dart';

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
  String get pollingMetricsSummary => _pollingService.metricsSummary;
  String get relayMetricsSummary => _mobileCameraRelayService.metricsSummary;

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

  String get movementLabel =>
      effectiveState.carMoving ? 'Auto avanzando' : 'Auto detenido';

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

    return effectiveState.handState;
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
