import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/auto_state.dart';
import '../../../services/auto_socket_service.dart';
import '../../../services/backend_process_service.dart';
import '../../../services/mobile_camera_relay_service.dart';
import 'connection_controller.dart';
import 'drive_session_controller.dart';

class HomeController extends GetxController {
  final ConnectionController _connectionController =
      Get.find<ConnectionController>();
  final DriveSessionController _driveSessionController =
      Get.find<DriveSessionController>();

  Rx<SocketConnectionStatus> get connectionStatus =>
      _connectionController.connectionStatus;
  Rxn<AutoState> get latestState => _driveSessionController.latestState;
  RxString get errorMessage => _connectionController.errorMessage;
  Rxn<DateTime> get lastPacketAt => _driveSessionController.lastPacketAt;
  Rx<BackendRuntimeStatus> get backendRuntimeStatus =>
      _connectionController.backendRuntimeStatus;
  RxString get backendInfoMessage => _connectionController.backendInfoMessage;
  RxString get backendRecentLog => _connectionController.backendRecentLog;
  Rx<MobileCameraRelayStatus> get mobileCameraStatus =>
      _driveSessionController.mobileCameraStatus;
  RxString get mobileCameraInfoMessage =>
      _driveSessionController.mobileCameraInfoMessage;
  RxBool get isDiagnosticsVisible =>
      _driveSessionController.isDiagnosticsVisible;

  TextEditingController get hostTextController =>
      _connectionController.hostTextController;
  TextEditingController get portTextController =>
      _connectionController.portTextController;

  AutoState get effectiveState => _driveSessionController.effectiveState;
  bool get hasData => _driveSessionController.hasData;
  bool get isConnecting => _connectionController.isConnecting;
  bool get isConnected => _connectionController.isConnected;
  bool get canAutoStartBackend => _connectionController.canAutoStartBackend;
  bool get isMobileClient => _connectionController.isMobileClient;
  bool get hasConfiguredHostOverride =>
      _connectionController.hasConfiguredHostOverride;
  bool get isLoopbackHost => _connectionController.isLoopbackHost;
  bool get canRestartManagedBackend =>
      _connectionController.canRestartManagedBackend;
  bool get canUsePhoneCamera => _driveSessionController.canUsePhoneCamera;
  bool get isPhoneCameraReady => _driveSessionController.isPhoneCameraReady;
  bool get isPhoneCameraStreaming =>
      _driveSessionController.isPhoneCameraStreaming;
  CameraController? get phoneCameraController =>
      _driveSessionController.phoneCameraController;
  bool get showPhoneCameraPanel => _driveSessionController.showPhoneCameraPanel;
  bool get showImmersiveMobileHome =>
      _driveSessionController.showImmersiveMobileHome;

  String get backendCommand => _connectionController.backendCommand;
  String get endpointLabel => _connectionController.endpointLabel;
  String get connectionSectionTitle =>
      _connectionController.connectionSectionTitle;
  String get connectionIntro => _connectionController.connectionIntro;
  String get connectionHint => _connectionController.connectionHint;
  String get backendActionHint => _connectionController.backendActionHint;
  String get phoneCameraStatusLabel =>
      _driveSessionController.phoneCameraStatusLabel;
  String get statusLabel => _connectionController.statusLabel;
  String get backendStatusLabel => _connectionController.backendStatusLabel;
  String get movementLabel => _driveSessionController.movementLabel;
  String get packetLabel => _driveSessionController.packetLabel;
  String get handSummary => _driveSessionController.handSummary;
  String get statePreview => _driveSessionController.statePreview;
  String get cameraSummary => _driveSessionController.cameraSummary;

  Future<void> connect() => _connectionController.connect();

  Future<void> disconnect() => _connectionController.disconnect();

  Future<void> toggleConnection() => _connectionController.toggleConnection();

  Future<void> restartManagedBackend() =>
      _connectionController.restartManagedBackend();

  Future<void> openDiagnosticsPanel() =>
      _driveSessionController.openDiagnosticsPanel();

  void closeDiagnosticsPanel() =>
      _driveSessionController.closeDiagnosticsPanel();

  @override
  void onInit() {
    super.onInit();
    _driveSessionController.prepareSessionExperience();
    _connectionController.initializeConnectionFlow();
  }
}
