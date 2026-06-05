import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/enums/bluetooth_output_mode.dart';
import '../../../data/enums/car_command.dart';
import '../../../data/models/auto_state.dart';
import '../../../services/auto_state_polling_service.dart';
import '../../../services/backend_process_service.dart';
import '../../../services/bluetooth_command_service.dart';
import '../../../services/mobile_camera_relay_service.dart';
import 'bluetooth_controller.dart';
import 'connection_controller.dart';
import 'drive_session_controller.dart';

class HomeController extends GetxController {
  final BluetoothController _bluetoothController =
      Get.find<BluetoothController>();
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
  RxBool get isDeveloperModeEnabled =>
      _driveSessionController.isDeveloperModeEnabled;
  RxBool get isBluetoothConnected => _bluetoothController.isConnected;
  RxBool get isBluetoothMockMode => _bluetoothController.isMockMode;
  RxBool get isBluetoothLoadingDevices => _bluetoothController.isLoadingDevices;
  RxBool get isManualBuzzerControlEnabled =>
      _bluetoothController.isManualBuzzerControlEnabled;
  Rx<BluetoothOutputMode> get bluetoothOutputMode =>
      _bluetoothController.outputMode;
  Rxn<CarCommand> get lastBluetoothCommand => _bluetoothController.lastCommand;
  RxString get lastBluetoothCommandLabel =>
      _bluetoothController.lastCommandLabel;
  RxString get lastBluetoothPayload => _bluetoothController.lastPayload;
  RxString get bluetoothErrorMessage => _bluetoothController.errorMessage;
  RxList<BluetoothDeviceInfo> get pairedBluetoothDevices =>
      _bluetoothController.pairedDevices;
  RxnString get selectedBluetoothDeviceAddress =>
      _bluetoothController.selectedDeviceAddress;
  RxString get selectedBluetoothDeviceName =>
      _bluetoothController.selectedDeviceName;
  RxnString get connectedBluetoothDeviceAddress =>
      _bluetoothController.connectedDeviceAddress;
  RxString get connectedBluetoothDeviceName =>
      _bluetoothController.connectedDeviceName;

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
  bool get canUseDeveloperMode => _driveSessionController.canUseDeveloperMode;

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
  String get demoBackendStatusLabel =>
      _driveSessionController.demoBackendStatusLabel;
  String get demoBackendStatusMessage =>
      _driveSessionController.demoBackendStatusMessage;
  String get observabilitySummary => [
    _driveSessionController.pollingMetricsSummary,
    _driveSessionController.relayMetricsSummary,
    _bluetoothController.metricsSummary,
  ].join('\n\n');

  Future<void> connect() => _connectionController.connect();

  Future<void> disconnect() => _connectionController.disconnect();

  Future<void> toggleConnection() => _connectionController.toggleConnection();

  Future<void> restartManagedBackend() =>
      _connectionController.restartManagedBackend();

  Future<void> connectBluetooth() => _bluetoothController.connect();

  Future<void> disconnectBluetooth() => _bluetoothController.disconnect();

  Future<void> toggleBluetoothConnection() =>
      _bluetoothController.toggleConnection();

  Future<void> connectSelectedBluetoothDevice() =>
      _bluetoothController.connectSelectedDevice();

  Future<void> refreshPairedBluetoothDevices() =>
      _bluetoothController.refreshPairedDevices();

  Future<void> sendForward() => _bluetoothController.sendForward();

  Future<void> sendStop() => _bluetoothController.sendStop();

  Future<void> sendLeft() => _bluetoothController.sendLeft();

  Future<void> sendRight() => _bluetoothController.sendRight();

  Future<void> sendBackward() => _bluetoothController.sendBackward();

  Future<void> sendHorn() => _bluetoothController.sendHorn();

  void enableAutoVirtualBluetoothMode() =>
      _bluetoothController.enableAutoVirtualMode();

  void enableBuzzerRealBluetoothMode() =>
      _bluetoothController.enableBuzzerRealMode();

  void selectBluetoothDevice(String? address) =>
      _bluetoothController.selectDevice(address);

  Future<void> openDiagnosticsPanel() =>
      _driveSessionController.openDiagnosticsPanel();

  Future<void> openControlCenter() =>
      _driveSessionController.openControlCenter();

  void toggleDeveloperMode() => _driveSessionController.toggleDeveloperMode();

  void closeDiagnosticsPanel() =>
      _driveSessionController.closeDiagnosticsPanel();

  void closeControlCenter() => _driveSessionController.closeControlCenter();

  @override
  void onInit() {
    super.onInit();
    _driveSessionController.prepareSessionExperience();
    _connectionController.initializeConnectionFlow();
  }
}
