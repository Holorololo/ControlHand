import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'bluetooth_command_service.dart';

class MockBluetoothCommandService extends GetxService
    implements BluetoothCommandService {
  bool _isConnected = false;
  String _lastCommand = '';
  String _lastError = '';
  Duration? _lastConnectDuration;
  Duration? _lastSendDuration;
  DateTime? _permissionRequestedAt;
  String? _connectedDeviceAddress;
  String? _connectedDeviceName;
  List<BluetoothDeviceInfo> pairedDevices = const <BluetoothDeviceInfo>[
    BluetoothDeviceInfo(name: 'Mock HC-05', address: 'MOCK-HC05'),
  ];

  int connectCallCount = 0;
  int disconnectCallCount = 0;
  int sendCallCount = 0;
  String? lastConnectAddress;

  @override
  bool get isConnected => _isConnected;

  @override
  bool get isSupported => true;

  @override
  String get lastError => _lastError;

  @override
  String get lastCommand => _lastCommand;

  @override
  Duration? get lastConnectDuration => _lastConnectDuration;

  @override
  Duration? get lastSendDuration => _lastSendDuration;

  @override
  DateTime? get permissionRequestedAt => _permissionRequestedAt;

  @override
  String? get connectedDeviceAddress => _connectedDeviceAddress;

  @override
  String? get connectedDeviceName => _connectedDeviceName;

  @override
  Future<void> connect({String? address}) async {
    connectCallCount++;
    _permissionRequestedAt = DateTime.now();
    _lastConnectDuration = Duration.zero;
    _isConnected = true;
    _lastError = '';
    lastConnectAddress = address;
    final selectedDevice = pairedDevices.firstWhere(
      (device) => device.address == (address ?? 'MOCK-HC05'),
      orElse: () => BluetoothDeviceInfo(
        name: 'Mock HC-05',
        address: address ?? 'MOCK-HC05',
      ),
    );
    _connectedDeviceAddress = selectedDevice.address;
    _connectedDeviceName = selectedDevice.name;
    debugPrint('MockBluetoothCommandService -> connected');
  }

  @override
  Future<void> disconnect() async {
    disconnectCallCount++;
    _isConnected = false;
    _connectedDeviceAddress = null;
    _connectedDeviceName = null;
    debugPrint('MockBluetoothCommandService -> disconnected');
  }

  @override
  Future<void> sendCommand(String payload) async {
    if (!_isConnected) {
      return;
    }

    sendCallCount++;
    _lastSendDuration = Duration.zero;
    _lastCommand = payload;
    debugPrint('MockBluetoothCommandService -> $payload');
  }

  @override
  Future<List<BluetoothDeviceInfo>> getPairedDevices() async {
    return List<BluetoothDeviceInfo>.from(pairedDevices);
  }
}
