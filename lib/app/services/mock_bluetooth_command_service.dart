import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'bluetooth_command_service.dart';

class MockBluetoothCommandService extends GetxService
    implements BluetoothCommandService {
  bool _isConnected = false;
  String _lastCommand = '';

  int connectCallCount = 0;
  int disconnectCallCount = 0;
  int sendCallCount = 0;

  @override
  bool get isConnected => _isConnected;

  @override
  String get lastCommand => _lastCommand;

  @override
  Future<void> connect() async {
    connectCallCount++;
    _isConnected = true;
    debugPrint('MockBluetoothCommandService -> connected');
  }

  @override
  Future<void> disconnect() async {
    disconnectCallCount++;
    _isConnected = false;
    debugPrint('MockBluetoothCommandService -> disconnected');
  }

  @override
  Future<void> sendCommand(String payload) async {
    if (!_isConnected) {
      return;
    }

    sendCallCount++;
    _lastCommand = payload;
    debugPrint('MockBluetoothCommandService -> $payload');
  }
}
