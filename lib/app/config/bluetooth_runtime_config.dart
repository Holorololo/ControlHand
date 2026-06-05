class BluetoothRuntimeConfig {
  const BluetoothRuntimeConfig._();

  static const bool useClassicBluetooth = bool.fromEnvironment(
    'USE_CLASSIC_BLUETOOTH',
    defaultValue: false,
  );

  static const String defaultClassicDeviceAddress = String.fromEnvironment(
    'CLASSIC_BT_ADDRESS',
    defaultValue: '',
  );

  static const String defaultClassicDeviceName = String.fromEnvironment(
    'CLASSIC_BT_NAME',
    defaultValue: '',
  );
}
