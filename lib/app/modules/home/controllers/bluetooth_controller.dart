import 'dart:async';

import 'package:get/get.dart';

import '../../../data/enums/bluetooth_output_mode.dart';
import '../../../data/enums/buzzer_command.dart';
import '../../../data/enums/car_command.dart';
import '../../../data/mappers/buzzer_command_mapper.dart';
import '../../../data/mappers/car_command_mapper.dart';
import '../../../data/models/auto_state.dart';
import '../../../services/auto_state_polling_service.dart';
import '../../../services/bluetooth_command_service.dart';

class BluetoothController extends GetxController {
  BluetoothController({
    BluetoothCommandService? bluetoothService,
    AutoStatePollingService? pollingService,
    this.enableStateSync = true,
    this.startConnected = true,
    this.isMockModeDefault = true,
    this.initialOutputMode = BluetoothOutputMode.autoVirtual,
  }) : _bluetoothService = bluetoothService,
       _pollingService = pollingService;

  final BluetoothCommandService? _bluetoothService;
  final AutoStatePollingService? _pollingService;
  final bool enableStateSync;
  final bool startConnected;
  final bool isMockModeDefault;
  final BluetoothOutputMode initialOutputMode;

  final RxBool isConnected = false.obs;
  final RxBool isMockMode = true.obs;
  final RxBool isLoadingDevices = false.obs;
  final Rx<BluetoothOutputMode> outputMode =
      BluetoothOutputMode.autoVirtual.obs;
  final Rxn<CarCommand> lastCommand = Rxn<CarCommand>();
  final Rxn<BuzzerCommand> lastBuzzerCommand = Rxn<BuzzerCommand>();
  final RxString lastCommandLabel = ''.obs;
  final RxString lastPayload = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxList<BluetoothDeviceInfo> pairedDevices = <BluetoothDeviceInfo>[].obs;
  final RxnString selectedDeviceAddress = RxnString();
  final RxString selectedDeviceName = ''.obs;
  final RxnString connectedDeviceAddress = RxnString();
  final RxString connectedDeviceName = ''.obs;

  Worker? _handStateWorker;
  String? _lastDispatchedPayload;

  BluetoothCommandService get _service =>
      _bluetoothService ?? Get.find<BluetoothCommandService>();

  AutoStatePollingService get _statePollingService =>
      _pollingService ?? Get.find<AutoStatePollingService>();

  Future<void> connect({String? address}) async {
    try {
      final targetAddress = address ?? selectedDeviceAddress.value;
      await _service.connect(address: targetAddress);
      isConnected.value = _service.isConnected;
      _lastDispatchedPayload = null;
      errorMessage.value = '';
      _syncConnectedDeviceState();
      _syncSelectedDeviceFromConnection();
    } catch (error) {
      isConnected.value = false;
      _lastDispatchedPayload = null;
      errorMessage.value = _readServiceError(fallback: error.toString());
    }
  }

  Future<void> disconnect() async {
    try {
      await _service.disconnect();
      errorMessage.value = '';
    } catch (error) {
      errorMessage.value = _readServiceError(fallback: error.toString());
    } finally {
      isConnected.value = _service.isConnected;
      _lastDispatchedPayload = null;
      _syncConnectedDeviceState();
    }
  }

  Future<void> toggleConnection() async {
    if (isConnected.value) {
      await disconnect();
      return;
    }

    await connect();
  }

  Future<void> sendCarCommand(CarCommand command) async {
    final payload = CarCommandMapper.toPayload(command);
    await _sendBluetoothPayload(
      payload: payload,
      commandLabel: CarCommandMapper.toVisualText(command),
      carCommand: command,
    );
  }

  Future<void> sendCommandFromHandStatus(String handStatus) async {
    final command = CarCommandMapper.fromHandStatus(handStatus);
    await sendCarCommand(command);
  }

  Future<void> sendBuzzerCommand(BuzzerCommand command) async {
    final payload = BuzzerCommandMapper.toPayload(command);
    await _sendBluetoothPayload(
      payload: payload,
      commandLabel: BuzzerCommandMapper.toVisualText(command),
      buzzerCommand: command,
    );
  }

  Future<void> sendBuzzerCommandFromHandStatus(String handStatus) async {
    final command = BuzzerCommandMapper.fromHandStatus(handStatus);
    await sendBuzzerCommand(command);
  }

  Future<void> sendForward() => sendCarCommand(CarCommand.forward);

  Future<void> sendStop() => sendCarCommand(CarCommand.stop);

  Future<void> sendLeft() => sendCarCommand(CarCommand.left);

  Future<void> sendRight() => sendCarCommand(CarCommand.right);

  Future<void> sendBackward() => sendCarCommand(CarCommand.backward);

  Future<void> sendBuzzerOn() => sendBuzzerCommand(BuzzerCommand.on);

  Future<void> sendBuzzerOff() => sendBuzzerCommand(BuzzerCommand.off);

  void enableAutoVirtualMode() {
    outputMode.value = BluetoothOutputMode.autoVirtual;
    _lastDispatchedPayload = null;
  }

  void enableBuzzerRealMode() {
    outputMode.value = BluetoothOutputMode.buzzerReal;
    _lastDispatchedPayload = null;
  }

  void selectDevice(String? address) {
    final normalizedAddress = address?.trim();
    if (normalizedAddress == null || normalizedAddress.isEmpty) {
      selectedDeviceAddress.value = null;
      selectedDeviceName.value = '';
      return;
    }

    selectedDeviceAddress.value = normalizedAddress;
    BluetoothDeviceInfo? selectedDevice;
    for (final device in pairedDevices) {
      if (device.address == normalizedAddress) {
        selectedDevice = device;
        break;
      }
    }
    selectedDeviceName.value = selectedDevice?.name ?? '';
  }

  Future<void> refreshPairedDevices() async {
    isLoadingDevices.value = true;

    try {
      final devices = await _service.getPairedDevices();
      pairedDevices.assignAll(devices);
      errorMessage.value = '';
      _preserveSelectedDevice(devices);
    } catch (error) {
      pairedDevices.clear();
      errorMessage.value = _readServiceError(fallback: error.toString());
    } finally {
      isLoadingDevices.value = false;
    }
  }

  Future<void> connectSelectedDevice() async {
    await connect(address: selectedDeviceAddress.value);
  }

  Future<void> _sendBluetoothPayload({
    required String payload,
    required String commandLabel,
    CarCommand? carCommand,
    BuzzerCommand? buzzerCommand,
  }) async {
    if (!isConnected.value || _lastDispatchedPayload == payload) {
      return;
    }

    try {
      await _service.sendCommand(payload);
      _lastDispatchedPayload = payload;
      lastCommand.value = carCommand;
      lastBuzzerCommand.value = buzzerCommand;
      lastCommandLabel.value = commandLabel;
      lastPayload.value = payload;
      errorMessage.value = '';
    } catch (error) {
      errorMessage.value = _readServiceError(fallback: error.toString());
    }
  }

  void _handleAutoState(AutoState? state) {
    if (state == null) {
      return;
    }

    final handStatus = state.handDetected ? state.handState : 'none';
    if (outputMode.value == BluetoothOutputMode.buzzerReal) {
      unawaited(sendBuzzerCommandFromHandStatus(handStatus));
      return;
    }

    unawaited(sendCommandFromHandStatus(handStatus));
  }

  @override
  void onInit() {
    super.onInit();
    isMockMode.value = isMockModeDefault;
    outputMode.value = initialOutputMode;
    _syncConnectedDeviceState();
    unawaited(refreshPairedDevices());

    if (startConnected) {
      unawaited(connect());
    }

    if (enableStateSync) {
      _handStateWorker = ever<AutoState?>(
        _statePollingService.latestState,
        _handleAutoState,
      );
    }
  }

  @override
  void onClose() {
    _handStateWorker?.dispose();
    unawaited(disconnect());
    super.onClose();
  }

  void _syncConnectedDeviceState() {
    connectedDeviceAddress.value = _service.connectedDeviceAddress;
    connectedDeviceName.value = _service.connectedDeviceName ?? '';
  }

  void _syncSelectedDeviceFromConnection() {
    final currentAddress = _service.connectedDeviceAddress;
    if (currentAddress != null && currentAddress.isNotEmpty) {
      selectDevice(currentAddress);
    }
  }

  void _preserveSelectedDevice(List<BluetoothDeviceInfo> devices) {
    if (devices.isEmpty) {
      selectedDeviceAddress.value = null;
      selectedDeviceName.value = '';
      return;
    }

    final currentSelection = selectedDeviceAddress.value;
    if (currentSelection != null &&
        devices.any((device) => device.address == currentSelection)) {
      selectDevice(currentSelection);
      return;
    }

    final connectedAddress = _service.connectedDeviceAddress;
    if (connectedAddress != null &&
        devices.any((device) => device.address == connectedAddress)) {
      selectDevice(connectedAddress);
      return;
    }

    selectDevice(devices.first.address);
  }

  String _readServiceError({required String fallback}) {
    final serviceError = _service.lastError.trim();
    return _normalizeErrorMessage(
      serviceError.isEmpty ? fallback : serviceError,
    );
  }

  String _normalizeErrorMessage(String rawMessage) {
    var message = rawMessage.trim();
    const prefixes = <String>[
      'Bad state:',
      'Exception:',
      'Unsupported operation:',
    ];

    for (final prefix in prefixes) {
      if (message.startsWith(prefix)) {
        message = message.substring(prefix.length).trim();
      }
    }

    return message;
  }
}
