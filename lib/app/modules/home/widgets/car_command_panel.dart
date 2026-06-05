import 'package:flutter/material.dart';

import '../../../data/enums/buzzer_command.dart';
import '../../../data/enums/car_command.dart';
import 'bluetooth_status_panel.dart';
import 'home_presentation_models.dart';
import 'home_widget_support.dart';
import 'manual_car_control_panel.dart';
import 'manual_buzzer_control_panel.dart';

class CarCommandPanel extends StatelessWidget {
  const CarCommandPanel({
    required this.bluetoothStatusViewModel,
    required this.activeCommand,
    required this.activeBuzzerCommand,
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
    required this.onBuzzerOn,
    required this.onBuzzerOff,
    super.key,
  });

  final BluetoothStatusViewModel bluetoothStatusViewModel;
  final CarCommand? activeCommand;
  final BuzzerCommand? activeBuzzerCommand;
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
  final VoidCallback onBuzzerOn;
  final VoidCallback onBuzzerOff;

  @override
  Widget build(BuildContext context) {
    return PanelShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Comandos del auto',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Capa preparada para enviar comandos por Bluetooth clasico. '
            'Puedes alternar entre el auto virtual y el buzzer real sin tocar el backend.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          BluetoothStatusPanel(
            viewModel: bluetoothStatusViewModel,
            onToggleConnection: onToggleBluetoothConnection,
            onSelectAutoVirtualMode: onSelectAutoVirtualMode,
            onSelectBuzzerRealMode: onSelectBuzzerRealMode,
            onSelectDevice: onSelectBluetoothDevice,
            onRefreshDevices: onRefreshBluetoothDevices,
          ),
          const SizedBox(height: 16),
          bluetoothStatusViewModel.isBuzzerOutputMode
              ? ManualBuzzerControlPanel(
                  isConnected: bluetoothStatusViewModel.isConnected,
                  activeCommand: activeBuzzerCommand,
                  onTurnOn: onBuzzerOn,
                  onTurnOff: onBuzzerOff,
                )
              : ManualCarControlPanel(
                  isConnected: bluetoothStatusViewModel.isConnected,
                  activeCommand: activeCommand,
                  onForward: onForward,
                  onStop: onStop,
                  onLeft: onLeft,
                  onRight: onRight,
                  onBackward: onBackward,
                ),
        ],
      ),
    );
  }
}
