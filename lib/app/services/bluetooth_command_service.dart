abstract class BluetoothCommandService {
  // Una implementacion real puede conectarse aqui usando flutter_blue_plus
  // para BLE o flutter_bluetooth_classic_serial para Bluetooth clasico.
  Future<void> connect();

  Future<void> disconnect();

  Future<void> sendCommand(String payload);

  bool get isConnected;

  String get lastCommand;
}
