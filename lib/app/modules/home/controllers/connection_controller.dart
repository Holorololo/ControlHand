import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/auto_state_polling_service.dart';
import '../../../services/backend_process_service.dart';
import '../../../services/mobile_camera_relay_service.dart';

class ConnectionController extends GetxController {
  ConnectionController({this.autoConnect = true});

  final bool autoConnect;

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

  final AutoStatePollingService _pollingService =
      Get.find<AutoStatePollingService>();
  final BackendProcessService _backendProcessService =
      Get.find<BackendProcessService>();
  final MobileCameraRelayService _mobileCameraRelayService =
      Get.find<MobileCameraRelayService>();

  late final TextEditingController hostTextController = TextEditingController(
    text: _resolveInitialHost(),
  );
  late final TextEditingController portTextController = TextEditingController(
    text: _backendPortOverride.toString(),
  );

  Rx<SocketConnectionStatus> get connectionStatus => _pollingService.status;
  RxString get errorMessage => _pollingService.errorMessage;
  Rx<BackendRuntimeStatus> get backendRuntimeStatus =>
      _backendProcessService.status;
  RxString get backendInfoMessage => _backendProcessService.infoMessage;
  RxString get backendRecentLog => _backendProcessService.recentLog;

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

  void initializeConnectionFlow() {
    if (_shouldAutoConnectOnLaunch()) {
      unawaited(connect());
    }
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
    await _pollingService.connect(host: host, port: port);

    if (_pollingService.status.value == SocketConnectionStatus.connected &&
        canUsePhoneCamera) {
      await _mobileCameraRelayService.startRelay(host: host, port: port);
    }
  }

  Future<void> disconnect() async {
    if (canUsePhoneCamera) {
      await _mobileCameraRelayService.stopRelay();
    }
    await _pollingService.disconnect();
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

  @override
  void onClose() {
    hostTextController.dispose();
    portTextController.dispose();
    super.onClose();
  }
}
