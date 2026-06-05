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
  final RxBool isManualBuzzerControlEnabled = false.obs;
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

  static const Duration _manualCommandDebounce = Duration(milliseconds: 180);

  Worker? _handStateWorker;
  String? _lastDispatchedPayload;
  _BluetoothPayloadRequest? _queuedPayloadRequest;
  DateTime? _lastManualDispatchAt;
  bool _wasHandOpen = false;
  bool _sendInProgress = false;

  BluetoothCommandService get _service =>
      _bluetoothService ?? Get.find<BluetoothCommandService>();

  AutoStatePollingService get _statePollingService =>
      _pollingService ?? Get.find<AutoStatePollingService>();

  Duration? get bluetoothConnectDuration => _service.lastConnectDuration;
  Duration? get lastBluetoothSendDuration => _service.lastSendDuration;
  DateTime? get permissionRequestedAt => _service.permissionRequestedAt;
  String get metricsSummary => [
    'bluetooth:',
    '  status: ${isConnected.value ? 'connected' : 'disconnected'}',
    '  output_mode: ${outputMode.value.name}',
    '  last_payload: ${lastPayload.value.isEmpty ? 'none' : lastPayload.value}',
    '  last_connect_ms: ${bluetoothConnectDuration?.inMilliseconds ?? 'n/a'}',
    '  last_send_ms: ${lastBluetoothSendDuration?.inMilliseconds ?? 'n/a'}',
    '  permission_requested_at: ${permissionRequestedAt?.toIso8601String() ?? 'n/a'}',
    '  last_error: ${errorMessage.value.isEmpty ? 'none' : errorMessage.value}',
  ].join('\n');

  Future<void> connect({String? address}) async {
    try {
      final targetAddress = address ?? selectedDeviceAddress.value;
      await _service.connect(address: targetAddress);
      _setRxIfChanged<bool>(isConnected, _service.isConnected);
      _lastDispatchedPayload = null;
      _queuedPayloadRequest = null;
      _lastManualDispatchAt = null;
      _setRxIfChanged<String>(errorMessage, '');
      _syncConnectedDeviceState();
      _syncSelectedDeviceFromConnection();
    } catch (error) {
      _setRxIfChanged<bool>(isConnected, false);
      _lastDispatchedPayload = null;
      _queuedPayloadRequest = null;
      _setRxIfChanged<String>(
        errorMessage,
        _readServiceError(fallback: error.toString()),
      );
    }
  }

  Future<void> disconnect() async {
    try {
      await _service.disconnect();
      _setRxIfChanged<String>(errorMessage, '');
    } catch (error) {
      _setRxIfChanged<String>(
        errorMessage,
        _readServiceError(fallback: error.toString()),
      );
    } finally {
      _setRxIfChanged<bool>(isConnected, _service.isConnected);
      _lastDispatchedPayload = null;
      _queuedPayloadRequest = null;
      _lastManualDispatchAt = null;
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

  Future<void> sendCarCommand(
    CarCommand command, {
    bool isManual = true,
  }) async {
    final payload = CarCommandMapper.toPayload(command);
    await _dispatchBluetoothPayload(
      payload: payload,
      commandLabel: CarCommandMapper.toVisualText(command),
      carCommand: command,
      isManual: isManual,
      reportDisconnected: isManual,
    );
  }

  Future<void> sendCommandFromHandStatus(String handStatus) async {
    final command = CarCommandMapper.fromHandStatus(handStatus);
    await sendCarCommand(command, isManual: false);
  }

  Future<void> sendBuzzerCommand(
    BuzzerCommand command, {
    bool isManual = true,
  }) async {
    final payload = BuzzerCommandMapper.toPayload(command);
    await _dispatchBluetoothPayload(
      payload: payload,
      commandLabel: BuzzerCommandMapper.toVisualText(command),
      buzzerCommand: command,
      isManual: isManual,
      reportDisconnected: isManual,
    );
  }

  Future<void> sendBuzzerCommandFromHandStatus(String handStatus) async {
    final command = BuzzerCommandMapper.fromHandStatus(handStatus);
    await sendBuzzerCommand(command, isManual: false);
  }

  Future<void> sendForward() => sendCarCommand(CarCommand.forward);

  Future<void> sendStop() => sendCarCommand(CarCommand.stop);

  Future<void> sendLeft() => sendCarCommand(CarCommand.left);

  Future<void> sendRight() => sendCarCommand(CarCommand.right);

  Future<void> sendBackward() => sendCarCommand(CarCommand.backward);

  Future<void> sendBuzzerOn() => sendBuzzerCommand(BuzzerCommand.on);

  Future<void> sendBuzzerOff() => sendBuzzerCommand(BuzzerCommand.off);

  void enableAutoVirtualMode() {
    _setRxIfChanged<BluetoothOutputMode>(
      outputMode,
      BluetoothOutputMode.autoVirtual,
    );
    _setRxIfChanged<bool>(isManualBuzzerControlEnabled, false);
    _lastDispatchedPayload = null;
  }

  void enableBuzzerRealMode() {
    _setRxIfChanged<BluetoothOutputMode>(
      outputMode,
      BluetoothOutputMode.buzzerReal,
    );
    _lastDispatchedPayload = null;
  }

  void selectDevice(String? address) {
    final normalizedAddress = address?.trim();
    if (normalizedAddress == null || normalizedAddress.isEmpty) {
      _setRxIfChanged<String?>(selectedDeviceAddress, null);
      _setRxIfChanged<String>(selectedDeviceName, '');
      return;
    }

    _setRxIfChanged<String?>(selectedDeviceAddress, normalizedAddress);
    BluetoothDeviceInfo? selectedDevice;
    for (final device in pairedDevices) {
      if (device.address == normalizedAddress) {
        selectedDevice = device;
        break;
      }
    }
    _setRxIfChanged<String>(selectedDeviceName, selectedDevice?.name ?? '');
  }

  Future<void> refreshPairedDevices() async {
    if (isLoadingDevices.value) {
      return;
    }

    _setRxIfChanged<bool>(isLoadingDevices, true);

    try {
      final devices = await _service.getPairedDevices();
      if (!_sameDeviceList(pairedDevices, devices)) {
        pairedDevices.assignAll(devices);
      }
      _setRxIfChanged<String>(errorMessage, '');
      _preserveSelectedDevice(devices);
    } catch (error) {
      if (pairedDevices.isNotEmpty) {
        pairedDevices.clear();
      }
      _setRxIfChanged<String>(
        errorMessage,
        _readServiceError(fallback: error.toString()),
      );
    } finally {
      _setRxIfChanged<bool>(isLoadingDevices, false);
    }
  }

  Future<void> connectSelectedDevice() async {
    await connect(address: selectedDeviceAddress.value);
  }

  Future<void> _dispatchBluetoothPayload({
    required String payload,
    required String commandLabel,
    CarCommand? carCommand,
    BuzzerCommand? buzzerCommand,
    required bool isManual,
    required bool reportDisconnected,
  }) async {
    final request = _BluetoothPayloadRequest(
      payload: payload,
      commandLabel: commandLabel,
      carCommand: carCommand,
      buzzerCommand: buzzerCommand,
      isManual: isManual,
      reportDisconnected: reportDisconnected,
    );

    if (!_canDispatchRequest(request)) {
      return;
    }

    if (_sendInProgress) {
      _queuedPayloadRequest = request;
      return;
    }

    _sendInProgress = true;

    try {
      await _service.sendCommand(payload);
      _lastDispatchedPayload = payload;
      if (request.isManual) {
        _lastManualDispatchAt = DateTime.now();
      }
      _setRxIfChanged<CarCommand?>(lastCommand, carCommand);
      _setRxIfChanged<BuzzerCommand?>(lastBuzzerCommand, buzzerCommand);
      _setRxIfChanged<String>(lastCommandLabel, commandLabel);
      _setRxIfChanged<String>(lastPayload, payload);
      _setRxIfChanged<String>(errorMessage, '');
    } catch (error) {
      _setRxIfChanged<String>(
        errorMessage,
        _readServiceError(fallback: error.toString()),
      );
    } finally {
      _sendInProgress = false;
    }

    final queuedRequest = _queuedPayloadRequest;
    _queuedPayloadRequest = null;
    if (queuedRequest != null) {
      await _dispatchBluetoothPayload(
        payload: queuedRequest.payload,
        commandLabel: queuedRequest.commandLabel,
        carCommand: queuedRequest.carCommand,
        buzzerCommand: queuedRequest.buzzerCommand,
        isManual: queuedRequest.isManual,
        reportDisconnected: queuedRequest.reportDisconnected,
      );
    }
  }

  void _handleAutoState(AutoState? state) {
    if (state == null) {
      return;
    }

    final handStatus = state.handDetected ? state.handState : 'none';
    _syncManualBuzzerControlAvailability(handStatus);

    if (outputMode.value == BluetoothOutputMode.buzzerReal) {
      unawaited(sendBuzzerCommandFromHandStatus(handStatus));
      return;
    }

    unawaited(sendCommandFromHandStatus(handStatus));
  }

  @override
  void onInit() {
    super.onInit();
    _setRxIfChanged<bool>(isMockMode, isMockModeDefault);
    _setRxIfChanged<BluetoothOutputMode>(outputMode, initialOutputMode);
    _syncConnectedDeviceState();

    if (isMockModeDefault) {
      unawaited(refreshPairedDevices());
    }

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
    _setRxIfChanged<String?>(
      connectedDeviceAddress,
      _service.connectedDeviceAddress,
    );
    _setRxIfChanged<String>(
      connectedDeviceName,
      _service.connectedDeviceName ?? '',
    );
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

  void _syncManualBuzzerControlAvailability(String handStatus) {
    final isHandOpen = _isOpenHandStatus(handStatus);
    if (isHandOpen && !_wasHandOpen) {
      _setRxIfChanged<bool>(isManualBuzzerControlEnabled, true);
    }

    _wasHandOpen = isHandOpen;
  }

  bool _isOpenHandStatus(String handStatus) {
    final normalized = handStatus.trim().toLowerCase();
    return normalized.contains('abierta') ||
        normalized.contains('open') ||
        normalized.contains('hand_open');
  }

  bool _canDispatchRequest(_BluetoothPayloadRequest request) {
    if (!isConnected.value) {
      if (request.reportDisconnected) {
        _setRxIfChanged<String>(
          errorMessage,
          'Conecta el modulo Bluetooth antes de enviar comandos manuales.',
        );
      }
      return false;
    }

    if (_lastDispatchedPayload == request.payload) {
      return false;
    }

    final queuedRequest = _queuedPayloadRequest;
    if (_sendInProgress &&
        (queuedRequest?.payload == request.payload ||
            _lastDispatchedPayload == request.payload)) {
      return false;
    }

    if (!request.isManual) {
      return true;
    }

    final lastManualDispatchAt = _lastManualDispatchAt;
    if (lastManualDispatchAt == null) {
      return true;
    }

    final elapsed = DateTime.now().difference(lastManualDispatchAt);
    return elapsed >= _manualCommandDebounce ||
        request.payload != _lastDispatchedPayload;
  }

  bool _sameDeviceList(
    List<BluetoothDeviceInfo> current,
    List<BluetoothDeviceInfo> next,
  ) {
    if (identical(current, next)) {
      return true;
    }

    if (current.length != next.length) {
      return false;
    }

    for (var index = 0; index < current.length; index++) {
      final currentDevice = current[index];
      final nextDevice = next[index];
      if (currentDevice.address != nextDevice.address ||
          currentDevice.name != nextDevice.name) {
        return false;
      }
    }

    return true;
  }

  void _setRxIfChanged<T>(dynamic rx, T value) {
    if (rx.value == value) {
      return;
    }

    rx.value = value;
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

class _BluetoothPayloadRequest {
  const _BluetoothPayloadRequest({
    required this.payload,
    required this.commandLabel,
    required this.carCommand,
    required this.buzzerCommand,
    required this.isManual,
    required this.reportDisconnected,
  });

  final String payload;
  final String commandLabel;
  final CarCommand? carCommand;
  final BuzzerCommand? buzzerCommand;
  final bool isManual;
  final bool reportDisconnected;
}
