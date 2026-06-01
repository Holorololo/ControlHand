import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/auto_state.dart';
import '../../../services/auto_socket_service.dart';
import '../../../services/backend_process_service.dart';
import '../../../services/mobile_camera_relay_service.dart';

class HomeController extends GetxController {
  HomeController(
    this._socketService,
    this._backendProcessService, {
    required MobileCameraRelayService mobileCameraRelayService,
    this.autoConnect = true,
  }) : _mobileCameraRelayService = mobileCameraRelayService;

  final AutoSocketService _socketService;
  final BackendProcessService _backendProcessService;
  final MobileCameraRelayService _mobileCameraRelayService;
  final bool autoConnect;
  final RxBool isDiagnosticsVisible = false.obs;

  static const String desktopBackendCommand =
      r'.\venv\Scripts\python.exe lib\assets\proyectoauto\main.py --mode backend --input-source desktop --host 0.0.0.0 --port 5000';
  static const String mobileBackendCommand =
      r'.\venv\Scripts\python.exe lib\assets\proyectoauto\main.py --mode backend --input-source mobile --host 0.0.0.0 --port 5000';
  static const String _backendHostOverride = String.fromEnvironment(
    'BACKEND_HOST',
    defaultValue: '',
  );
  static const int _backendPortOverride = int.fromEnvironment(
    'BACKEND_PORT',
    defaultValue: 5000,
  );

  late final TextEditingController hostTextController = TextEditingController(
    text: _resolveInitialHost(),
  );
  late final TextEditingController portTextController = TextEditingController(
    text: _backendPortOverride.toString(),
  );

  Rx<SocketConnectionStatus> get connectionStatus => _socketService.status;
  Rxn<AutoState> get latestState => _socketService.latestState;
  RxString get errorMessage => _socketService.errorMessage;
  Rxn<DateTime> get lastPacketAt => _socketService.lastPacketAt;
  Rx<BackendRuntimeStatus> get backendRuntimeStatus =>
      _backendProcessService.status;
  RxString get backendInfoMessage => _backendProcessService.infoMessage;
  RxString get backendRecentLog => _backendProcessService.recentLog;
  Rx<MobileCameraRelayStatus> get mobileCameraStatus =>
      _mobileCameraRelayService.status;
  RxString get mobileCameraInfoMessage => _mobileCameraRelayService.infoMessage;

  AutoState get effectiveState => latestState.value ?? AutoState.initial();
  bool get hasData => latestState.value != null;
  bool get isConnecting =>
      connectionStatus.value == SocketConnectionStatus.connecting;
  bool get isConnected =>
      connectionStatus.value == SocketConnectionStatus.connected;
  bool get canAutoStartBackend => _backendProcessService.canAutoStart;
  bool get isMobileClient => GetPlatform.isAndroid || GetPlatform.isIOS;
  bool get hasConfiguredHostOverride => _backendHostOverride.trim().isNotEmpty;
  bool get isLoopbackHost => _isLoopbackHost(hostTextController.text.trim());
  bool get canRestartManagedBackend =>
      _backendProcessService.canManageHost(hostTextController.text.trim());
  bool get canUsePhoneCamera => _mobileCameraRelayService.supported;
  bool get isPhoneCameraReady => _mobileCameraRelayService.hasPreview;
  bool get isPhoneCameraStreaming => _mobileCameraRelayService.isStreaming;
  CameraController? get phoneCameraController =>
      _mobileCameraRelayService.controller;
  bool get showPhoneCameraPanel => isMobileClient && canUsePhoneCamera;
  bool get showImmersiveMobileHome => isMobileClient && canUsePhoneCamera;

  String get backendCommand =>
      isMobileClient ? mobileBackendCommand : desktopBackendCommand;

  String get endpointLabel => _buildEndpointLabel(
    hostTextController.text.trim(),
    portTextController.text.trim(),
  );

  String get connectionSectionTitle =>
      canAutoStartBackend ? 'Conexion local' : 'Conexion remota';

  String get connectionIntro {
    if (canAutoStartBackend) {
      return 'En desktop Flutter puede iniciar el backend cuando usas 127.0.0.1. '
          'Si apuntas a otra IP o dominio, asumira que el backend corre fuera de esta app.';
    }

    return 'En el celular esta app usa la camara del telefono y envia frames al backend Python '
        'que esta corriendo en tu PC.';
  }

  String get connectionHint {
    if (canAutoStartBackend && isLoopbackHost) {
      return 'Modo local listo: Flutter puede iniciar y reiniciar Python en esta computadora.';
    }

    if (isLoopbackHost) {
      return 'En Android o iPhone, 127.0.0.1 apunta al propio telefono. '
          'Usa adb reverse por USB o cambia Host por la IP LAN de tu PC.';
    }

    if (canAutoStartBackend) {
      return 'Con una IP remota Flutter solo intentara conectarse; no iniciara Python local.';
    }

    return 'Verifica que el backend corra en tu PC con --input-source mobile, use --host 0.0.0.0 y que Windows Firewall permita el puerto 5000.';
  }

  String get backendActionHint {
    if (canRestartManagedBackend) {
      return 'Puedes dejar que Flutter administre el backend o correrlo manualmente con el comando de abajo.';
    }

    return 'Para este host debes levantar el backend manualmente en la computadora que procesara los frames del celular.';
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

  String get statusLabel {
    switch (connectionStatus.value) {
      case SocketConnectionStatus.connected:
        return 'Conectado';
      case SocketConnectionStatus.connecting:
        return 'Conectando';
      case SocketConnectionStatus.disconnected:
        return 'Desconectado';
    }
  }

  String get backendStatusLabel {
    switch (backendRuntimeStatus.value) {
      case BackendRuntimeStatus.idle:
        return 'Backend inactivo';
      case BackendRuntimeStatus.locating:
        return 'Buscando backend';
      case BackendRuntimeStatus.starting:
        return 'Iniciando backend';
      case BackendRuntimeStatus.running:
        return 'Backend iniciado por Flutter';
      case BackendRuntimeStatus.external:
        return 'Backend externo detectado';
      case BackendRuntimeStatus.unavailable:
        return 'Arranque automatico no disponible';
      case BackendRuntimeStatus.failed:
        return 'Fallo al iniciar backend';
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
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(effectiveState.toJson());
  }

  String get cameraSummary {
    if (effectiveState.hasCameraPreview) {
      return 'Vista en vivo recibida desde Flask/OpenCV.';
    }

    if (isPhoneCameraStreaming) {
      return 'La camara del celular esta enviando frames al backend. Esperando el primer preview procesado.';
    }

    if (effectiveState.backendMessage.isNotEmpty) {
      return effectiveState.backendMessage;
    }

    if (isConnected) {
      return 'Conectado, esperando el primer frame de la camara.';
    }

    if (backendInfoMessage.value.isNotEmpty) {
      return backendInfoMessage.value;
    }

    if (canAutoStartBackend && isLoopbackHost) {
      return 'Flutter intentara iniciar el backend Flask automaticamente.';
    }

    if (showPhoneCameraPanel && mobileCameraInfoMessage.value.isNotEmpty) {
      return mobileCameraInfoMessage.value;
    }

    return 'La app espera un backend Flask ya disponible en la red.';
  }

  Future<void> connect() async {
    final host = hostTextController.text.trim();
    final port = int.tryParse(portTextController.text.trim());

    if (host.isEmpty || port == null) {
      Get.snackbar(
        'Endpoint invalido',
        'Revisa el host y el puerto antes de conectar.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (canUsePhoneCamera) {
      await _mobileCameraRelayService.stopRelay();
    }

    await _backendProcessService.ensureStarted(host: host, port: port);
    await _socketService.connect(host: host, port: port);

    if (_socketService.status.value == SocketConnectionStatus.connected &&
        canUsePhoneCamera) {
      await _mobileCameraRelayService.startRelay(host: host, port: port);
    }

    update();
  }

  Future<void> disconnect() async {
    if (canUsePhoneCamera) {
      await _mobileCameraRelayService.stopRelay();
    }
    await _socketService.disconnect();
    update();
  }

  Future<void> toggleConnection() async {
    if (isConnected || isConnecting) {
      await disconnect();
      return;
    }

    await connect();
  }

  Future<void> restartManagedBackend() async {
    if (!canRestartManagedBackend) {
      Get.snackbar(
        'Backend externo',
        'Con este host Flutter no puede reiniciar Python local. Levantalo en tu PC y vuelve a conectar.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    await _backendProcessService.stopManagedBackend();
    await connect();
  }

  Future<void> openDiagnosticsPanel() async {
    isDiagnosticsVisible.value = true;
    _socketService.setPreviewStreamingEnabled(true);
  }

  void closeDiagnosticsPanel() {
    isDiagnosticsVisible.value = false;
    _socketService.setPreviewStreamingEnabled(!isMobileClient);
  }

  @override
  void onInit() {
    super.onInit();
    _socketService.setPreviewStreamingEnabled(!isMobileClient);
    if (showImmersiveMobileHome) {
      unawaited(_mobileCameraRelayService.preparePreview());
    }
    if (_shouldAutoConnectOnLaunch()) {
      unawaited(connect());
    }
  }

  @override
  void onClose() {
    if (canUsePhoneCamera) {
      unawaited(_mobileCameraRelayService.stopRelay(disposeCamera: true));
    }
    hostTextController.dispose();
    portTextController.dispose();
    super.onClose();
  }

  String _resolveInitialHost() {
    final hostOverride = _backendHostOverride.trim();
    if (hostOverride.isNotEmpty) {
      return hostOverride;
    }

    return '127.0.0.1';
  }

  bool _shouldAutoConnectOnLaunch() {
    if (!autoConnect) {
      return false;
    }

    if (!isMobileClient) {
      return true;
    }

    return hasConfiguredHostOverride;
  }

  String _buildEndpointLabel(String host, String portText) {
    if (host.isEmpty) {
      return 'sin definir';
    }

    if (host.contains('://')) {
      final uri = Uri.tryParse(host);
      if (uri != null && uri.hasPort) {
        return uri.toString().replaceFirst(RegExp(r'/$'), '');
      }

      return '$host:$portText';
    }

    return 'http://$host:$portText';
  }

  bool _isLoopbackHost(String host) {
    var normalizedHost = host.trim().toLowerCase();

    if (normalizedHost.contains('://')) {
      final uri = Uri.tryParse(normalizedHost);
      if (uri != null && uri.host.isNotEmpty) {
        normalizedHost = uri.host.toLowerCase();
      }
    }

    return normalizedHost == '127.0.0.1' ||
        normalizedHost == 'localhost' ||
        normalizedHost == '::1' ||
        normalizedHost == '[::1]';
  }
}
