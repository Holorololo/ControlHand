import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../data/enums/bluetooth_output_mode.dart';
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
      final preferredAddress = address?.trim();
      if ((preferredAddress == null || preferredAddress.isEmpty) &&
          pairedDevices.isEmpty &&
          !isLoadingDevices.value) {
        await refreshPairedDevices();
      }

      final targetAddress = preferredAddress?.isNotEmpty == true
          ? preferredAddress
          : selectedDeviceAddress.value;
      await _service.connect(address: targetAddress);
      _setRxIfChanged<bool>(isConnected, _service.isConnected);
      _lastDispatchedPayload = null;
      _queuedPayloadRequest = null;
      _lastManualDispatchAt = null;
      _setRxIfChanged<String>(errorMessage, '');
      if (outputMode.value == BluetoothOutputMode.buzzerReal) {
        _setRxIfChanged<bool>(isManualBuzzerControlEnabled, true);
      }
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
    bool allowDuplicatePayload = false,
  }) async {
    final payload = CarCommandMapper.toPayload(command);
    await _dispatchBluetoothPayload(
      payload: payload,
      commandLabel: CarCommandMapper.toVisualText(command),
      carCommand: command,
      isManual: isManual,
      reportDisconnected: isManual,
      allowDuplicatePayload: allowDuplicatePayload,
    );
  }

  Future<void> sendCommandFromHandStatus(
    String handStatus, {
    bool handDetected = true,
    int fingerCount = 0,
    String? backendCommand,
    String? payload,
  }) async {
    final command = CarCommandMapper.fromBackendState(
      handDetected: handDetected,
      handStatus: handStatus,
      fingerCount: fingerCount,
      backendCommand: backendCommand,
      payload: payload,
    );
    await sendCarCommand(command, isManual: false);
  }

  Future<void> sendCommandFromAutoState(AutoState state) async {
    final command = CarCommandMapper.fromAutoState(state);
    await sendCarCommand(command, isManual: false);
  }

  Future<void> sendForward() => sendCarCommand(CarCommand.forward);

  Future<void> sendStop() => sendCarCommand(CarCommand.stop);

  Future<void> sendLeft() => sendCarCommand(CarCommand.left);

  Future<void> sendRight() => sendCarCommand(CarCommand.right);

  Future<void> sendBackward() => sendCarCommand(CarCommand.backward);

  Future<void> sendHorn() =>
      sendCarCommand(CarCommand.horn, allowDuplicatePayload: true);

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
    _setRxIfChanged<bool>(isManualBuzzerControlEnabled, true);
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
    required bool isManual,
    required bool reportDisconnected,
    bool allowDuplicatePayload = false,
  }) async {
    final request = _BluetoothPayloadRequest(
      payload: payload,
      commandLabel: commandLabel,
      carCommand: carCommand,
      isManual: isManual,
      reportDisconnected: reportDisconnected,
      allowDuplicatePayload: allowDuplicatePayload,
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
      _setRxIfChanged<String>(lastCommandLabel, commandLabel);
      _setRxIfChanged<String>(lastPayload, payload);
      _setRxIfChanged<String>(errorMessage, '');
      if (kDebugMode) {
        debugPrint(
          'BluetoothController -> payload sent '
          '(payload=$payload, command=$commandLabel)',
        );
      }
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
        isManual: queuedRequest.isManual,
        reportDisconnected: queuedRequest.reportDisconnected,
        allowDuplicatePayload: queuedRequest.allowDuplicatePayload,
      );
    }
  }

  void _handleAutoState(AutoState? state) {
    if (state == null) {
      return;
    }

    final command = CarCommandMapper.fromAutoState(state);
    _setRxIfChanged<bool>(
      isManualBuzzerControlEnabled,
      state.handDetected && state.fingerCount > 0,
    );
    _applyVisualCommandState(command);

    if (outputMode.value == BluetoothOutputMode.buzzerReal) {
      unawaited(sendCommandFromAutoState(state));
      return;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _setRxIfChanged<bool>(isMockMode, isMockModeDefault);
    _setRxIfChanged<BluetoothOutputMode>(outputMode, initialOutputMode);
    _setRxIfChanged<bool>(
      isManualBuzzerControlEnabled,
      initialOutputMode == BluetoothOutputMode.buzzerReal,
    );
    _syncConnectedDeviceState();

    if (isMockModeDefault || _service.isSupported) {
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

  void _applyVisualCommandState(CarCommand command) {
    _setRxIfChanged<CarCommand?>(lastCommand, command);
    _setRxIfChanged<String>(
      lastCommandLabel,
      CarCommandMapper.toVisualText(command),
    );
    _setRxIfChanged<String>(lastPayload, CarCommandMapper.toPayload(command));
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

    if (!request.allowDuplicatePayload &&
        _lastDispatchedPayload == request.payload) {
      return false;
    }

    final queuedRequest = _queuedPayloadRequest;
    if (_sendInProgress &&
        !request.allowDuplicatePayload &&
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
    required this.isManual,
    required this.reportDisconnected,
    required this.allowDuplicatePayload,
  });

  final String payload;
  final String commandLabel;
  final CarCommand? carCommand;
  final bool isManual;
  final bool reportDisconnected;
  final bool allowDuplicatePayload;
}
