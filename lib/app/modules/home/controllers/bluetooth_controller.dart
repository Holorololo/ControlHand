import 'dart:async';

import 'package:get/get.dart';

import '../../../data/enums/car_command.dart';
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
  }) : _bluetoothService = bluetoothService,
       _pollingService = pollingService;

  final BluetoothCommandService? _bluetoothService;
  final AutoStatePollingService? _pollingService;
  final bool enableStateSync;
  final bool startConnected;
  final bool isMockModeDefault;

  final RxBool isConnected = false.obs;
  final RxBool isMockMode = true.obs;
  final Rxn<CarCommand> lastCommand = Rxn<CarCommand>();
  final RxString lastPayload = ''.obs;

  Worker? _handStateWorker;
  CarCommand? _lastDispatchedCommand;

  BluetoothCommandService get _service =>
      _bluetoothService ?? Get.find<BluetoothCommandService>();

  AutoStatePollingService get _statePollingService =>
      _pollingService ?? Get.find<AutoStatePollingService>();

  Future<void> connect() async {
    await _service.connect();
    isConnected.value = _service.isConnected;
    _lastDispatchedCommand = null;
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    isConnected.value = _service.isConnected;
    _lastDispatchedCommand = null;
  }

  Future<void> toggleConnection() async {
    if (isConnected.value) {
      await disconnect();
      return;
    }

    await connect();
  }

  Future<void> sendCarCommand(CarCommand command) async {
    if (!isConnected.value || _lastDispatchedCommand == command) {
      return;
    }

    final payload = CarCommandMapper.toPayload(command);
    await _service.sendCommand(payload);
    _lastDispatchedCommand = command;
    lastCommand.value = command;
    lastPayload.value = payload;
  }

  Future<void> sendCommandFromHandStatus(String handStatus) async {
    final command = CarCommandMapper.fromHandStatus(handStatus);
    await sendCarCommand(command);
  }

  Future<void> sendForward() => sendCarCommand(CarCommand.forward);

  Future<void> sendStop() => sendCarCommand(CarCommand.stop);

  Future<void> sendLeft() => sendCarCommand(CarCommand.left);

  Future<void> sendRight() => sendCarCommand(CarCommand.right);

  Future<void> sendBackward() => sendCarCommand(CarCommand.backward);

  void _handleAutoState(AutoState? state) {
    if (state == null) {
      return;
    }

    final handStatus = state.handDetected ? state.handState : 'none';
    unawaited(sendCommandFromHandStatus(handStatus));
  }

  @override
  void onInit() {
    super.onInit();
    isMockMode.value = isMockModeDefault;

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
}
