class BluetoothDeviceInfo {
  const BluetoothDeviceInfo({required this.name, required this.address});

  final String name;
  final String address;
}

class BluetoothCommandException implements Exception {
  const BluetoothCommandException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class BluetoothCommandService {
  // Una implementacion real puede conectarse aqui usando RFCOMM/SPP para
  // modulos HC-05 o HC-06 en Android.
  Future<void> connect({String? address});

  Future<void> disconnect();

  Future<void> sendCommand(String payload);

  Future<List<BluetoothDeviceInfo>> getPairedDevices();

  bool get isConnected;

  bool get isSupported;

  String get lastError;

  String get lastCommand;

  String? get connectedDeviceAddress;

  String? get connectedDeviceName;
}
