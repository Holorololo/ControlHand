import 'dart:io';

import 'package:bluetooth_serial_android/bluetooth_serial_android.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../config/bluetooth_runtime_config.dart';
import 'bluetooth_command_service.dart';

class ClassicBluetoothCommandService extends GetxService
    implements BluetoothCommandService {
  static const String _defaultSppUuid = '00001101-0000-1000-8000-00805F9B34FB';

  bool _isConnected = false;
  String _lastCommand = '';
  String _lastError = '';
  String? _connectedDeviceAddress;
  String? _connectedDeviceName;

  @override
  bool get isConnected => _isConnected;

  @override
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  @override
  String get lastCommand => _lastCommand;

  @override
  String get lastError => _lastError;

  @override
  String? get connectedDeviceAddress => _connectedDeviceAddress;

  @override
  String? get connectedDeviceName => _connectedDeviceName;

  @override
  Future<void> connect({String? address}) async {
    if (!isSupported) {
      _lastError =
          'Bluetooth clasico solo esta disponible en Android para HC-05/HC-06.';
      throw UnsupportedError(_lastError);
    }

    try {
      await _requestBluetoothPermissions();

      final pairedDevices = await getPairedDevices();
      final targetDevice = _resolveTargetDevice(
        address: address,
        pairedDevices: pairedDevices,
      );

      if (targetDevice == null) {
        _lastError =
            'No se encontro un modulo HC-05/HC-06 emparejado para conectar.';
        throw BluetoothCommandException(_lastError);
      }

      final connected = await FlutterBluetoothSerial.connect(
        targetDevice.address,
        uuid: _defaultSppUuid,
        timeoutMs: 400,
      );

      if (!connected) {
        _lastError =
            'No se pudo establecer la conexion RFCOMM con ${targetDevice.address}.';
        throw BluetoothCommandException(_lastError);
      }

      _isConnected = true;
      _lastError = '';
      _connectedDeviceAddress = targetDevice.address;
      _connectedDeviceName = targetDevice.name;
    } on PlatformException catch (error) {
      _isConnected = false;
      _lastError =
          error.message ?? 'Fallo de plataforma al conectar Bluetooth clasico.';
      throw BluetoothCommandException(_lastError);
    } catch (error) {
      _isConnected = false;
      if (_lastError.trim().isEmpty) {
        _lastError = _mapBluetoothPlatformError(
          error.toString(),
          fallback: 'Fallo inesperado al conectar Bluetooth clasico.',
        );
      }
      throw BluetoothCommandException(_lastError);
    }
  }

  @override
  Future<void> disconnect() async {
    if (!isSupported) {
      _isConnected = false;
      return;
    }

    try {
      await FlutterBluetoothSerial.disconnect();
    } catch (_) {
      // Preferimos limpiar el estado local aun si la libreria ya perdio el socket.
    } finally {
      _isConnected = false;
      _connectedDeviceAddress = null;
      _connectedDeviceName = null;
    }
  }

  @override
  Future<void> sendCommand(String payload) async {
    if (!isSupported) {
      _lastError = 'Bluetooth clasico no soportado en esta plataforma.';
      throw UnsupportedError(_lastError);
    }

    if (!_isConnected) {
      _lastError = 'No hay un dispositivo Bluetooth clasico conectado.';
      throw BluetoothCommandException(_lastError);
    }

    try {
      await FlutterBluetoothSerial.write(payload);
      _lastError = '';
      _lastCommand = payload;
      if (kDebugMode) {
        debugPrint('ClassicBluetoothCommandService -> $payload');
      }
    } on PlatformException catch (error) {
      _lastError =
          error.message ?? 'Error de plataforma al enviar datos por Bluetooth.';
      throw BluetoothCommandException(_lastError);
    }
  }

  @override
  Future<List<BluetoothDeviceInfo>> getPairedDevices() async {
    if (!isSupported) {
      return const <BluetoothDeviceInfo>[];
    }

    try {
      await _requestBluetoothPermissions();
      final rawDevices = await FlutterBluetoothSerial.getPairedDevices();
      return rawDevices
          .map(
            (device) => BluetoothDeviceInfo(
              name: (device['name'] ?? 'Sin nombre').trim(),
              address: (device['address'] ?? '').trim(),
            ),
          )
          .where((device) => device.address.isNotEmpty)
          .toList(growable: false);
    } on PlatformException catch (error) {
      _lastError = _mapBluetoothPlatformError(
        error.message,
        fallback:
            'No se pudieron listar los dispositivos Bluetooth emparejados.',
      );
      throw BluetoothCommandException(_lastError);
    } catch (error) {
      _lastError = _mapBluetoothPlatformError(
        error.toString(),
        fallback:
            'No se pudieron listar los dispositivos Bluetooth emparejados.',
      );
      throw BluetoothCommandException(_lastError);
    }
  }

  Future<void> _requestBluetoothPermissions() async {
    try {
      final permissionsGranted =
          await FlutterBluetoothSerial.ensurePermissions();
      if (permissionsGranted) {
        _lastError = '';
        return;
      }

      // La libreria devuelve false apenas dispara el dialogo de permisos y no
      // espera el callback del sistema. No lo tratamos como fallo definitivo.
      _lastError =
          'Android mostro o requiere permisos Bluetooth. Si ya aceptaste '
          '"Dispositivos cercanos", intenta de nuevo Refrescar o Conectar.';
    } on PlatformException catch (error) {
      _lastError = _mapBluetoothPlatformError(
        error.message,
        fallback: 'No se pudieron solicitar permisos Bluetooth en Android.',
      );
      throw BluetoothCommandException(_lastError);
    }
  }

  BluetoothDeviceInfo? _resolveTargetDevice({
    required String? address,
    required List<BluetoothDeviceInfo> pairedDevices,
  }) {
    final requestedAddress = (address ?? '').trim();
    if (requestedAddress.isNotEmpty) {
      return pairedDevices.cast<BluetoothDeviceInfo?>().firstWhere(
        (device) => device?.address == requestedAddress,
        orElse: () => BluetoothDeviceInfo(
          name: BluetoothRuntimeConfig.defaultClassicDeviceName.isEmpty
              ? 'HC-05/HC-06'
              : BluetoothRuntimeConfig.defaultClassicDeviceName,
          address: requestedAddress,
        ),
      );
    }

    final configuredAddress = BluetoothRuntimeConfig.defaultClassicDeviceAddress
        .trim();
    if (configuredAddress.isNotEmpty) {
      final matchedByAddress = pairedDevices
          .cast<BluetoothDeviceInfo?>()
          .firstWhere(
            (device) => device?.address == configuredAddress,
            orElse: () => null,
          );
      if (matchedByAddress != null) {
        return matchedByAddress;
      }
    }

    final configuredName = BluetoothRuntimeConfig.defaultClassicDeviceName
        .trim()
        .toLowerCase();
    if (configuredName.isNotEmpty) {
      final matchedByName = pairedDevices
          .cast<BluetoothDeviceInfo?>()
          .firstWhere(
            (device) => device?.name.toLowerCase() == configuredName,
            orElse: () => null,
          );
      if (matchedByName != null) {
        return matchedByName;
      }
    }

    if (pairedDevices.length == 1) {
      return pairedDevices.first;
    }

    final hcModule = pairedDevices.cast<BluetoothDeviceInfo?>().firstWhere((
      device,
    ) {
      final name = device?.name.toLowerCase() ?? '';
      return name.contains('hc-05') || name.contains('hc-06');
    }, orElse: () => null);
    if (hcModule != null) {
      return hcModule;
    }

    return pairedDevices.isEmpty ? null : pairedDevices.first;
  }

  String _mapBluetoothPlatformError(
    String? rawMessage, {
    required String fallback,
  }) {
    final message = (rawMessage ?? '').trim();
    final normalized = message.toLowerCase();

    if (normalized.contains('permission') ||
        normalized.contains('permiso') ||
        normalized.contains('securityexception')) {
      return 'Android bloqueo el acceso Bluetooth. Revisa "Dispositivos cercanos" '
          'y, si tu telefono lo pide, tambien permisos extra del sistema.';
    }

    if (normalized.contains('adapter') ||
        normalized.contains('bluetooth off') ||
        normalized.contains('disabled')) {
      return 'Bluetooth parece estar apagado en el telefono. Activalo e intenta otra vez.';
    }

    if (normalized.contains('connection_failed') ||
        normalized.contains('socket') ||
        normalized.contains('rfcomm')) {
      return 'No se pudo abrir la conexion con el HC-05/HC-06. '
          'Verifica que este emparejado y encendido.';
    }

    if (message.isEmpty) {
      return fallback;
    }

    return message;
  }
}
