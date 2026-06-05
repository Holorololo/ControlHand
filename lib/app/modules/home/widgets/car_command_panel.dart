import 'package:flutter/material.dart';

import '../../../data/enums/car_command.dart';
import 'bluetooth_status_panel.dart';
import 'buzzer_status_panel.dart';
import 'home_presentation_models.dart';
import 'home_widget_support.dart';
import 'manual_car_control_panel.dart';

class CarCommandPanel extends StatelessWidget {
  const CarCommandPanel({
    required this.bluetoothStatusViewModel,
    required this.activeCommand,
    required this.activePayload,
    required this.onToggleBluetoothConnection,
    required this.onSelectAutoVirtualMode,
    required this.onSelectBuzzerRealMode,
    required this.onSelectBluetoothDevice,
    required this.onRefreshBluetoothDevices,
    required this.onForward,
    required this.onStop,
    required this.onLeft,
    required this.onRight,
    required this.onBackward,
    required this.onHorn,
    this.developerMode = false,
    super.key,
  });

  final BluetoothStatusViewModel bluetoothStatusViewModel;
  final CarCommand? activeCommand;
  final String activePayload;
  final VoidCallback onToggleBluetoothConnection;
  final VoidCallback onSelectAutoVirtualMode;
  final VoidCallback onSelectBuzzerRealMode;
  final ValueChanged<String?> onSelectBluetoothDevice;
  final VoidCallback onRefreshBluetoothDevices;
  final VoidCallback onForward;
  final VoidCallback onStop;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onBackward;
  final VoidCallback onHorn;
  final bool developerMode;

  @override
  Widget build(BuildContext context) {
    return PanelShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Bluetooth y control',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Conecta tu HC-05/HC-06 y prueba los controles manuales.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (developerMode) ...<Widget>[
            const SizedBox(height: 16),
            BuzzerStatusPanel(
              viewModel: bluetoothStatusViewModel,
              activeCommand: activeCommand,
            ),
          ],
          const SizedBox(height: 16),
          BluetoothStatusPanel(
            viewModel: bluetoothStatusViewModel,
            onToggleConnection: onToggleBluetoothConnection,
            onSelectAutoVirtualMode: onSelectAutoVirtualMode,
            onSelectBuzzerRealMode: onSelectBuzzerRealMode,
            onSelectDevice: onSelectBluetoothDevice,
            onRefreshDevices: onRefreshBluetoothDevices,
            developerMode: developerMode,
          ),
          const SizedBox(height: 16),
          ManualCarControlPanel(
            isConnected: bluetoothStatusViewModel.isConnected,
            activeCommand: activeCommand,
            helperMessage: developerMode
                ? bluetoothStatusViewModel.manualBuzzerControlHint
                : '',
            onForward: onForward,
            onStop: onStop,
            onLeft: onLeft,
            onRight: onRight,
            onBackward: onBackward,
            onHorn: onHorn,
          ),
          if (activePayload.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            SoftChip(label: 'Payload actual $activePayload'),
          ],
        ],
      ),
    );
  }
}
