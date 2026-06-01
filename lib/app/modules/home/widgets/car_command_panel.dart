import 'package:flutter/material.dart';

import '../../../data/enums/car_command.dart';
import 'bluetooth_status_panel.dart';
import 'home_presentation_models.dart';
import 'home_widget_support.dart';
import 'manual_car_control_panel.dart';

class CarCommandPanel extends StatelessWidget {
  const CarCommandPanel({
    required this.bluetoothStatusViewModel,
    required this.activeCommand,
    required this.onToggleBluetoothConnection,
    required this.onForward,
    required this.onStop,
    required this.onLeft,
    required this.onRight,
    required this.onBackward,
    super.key,
  });

  final BluetoothStatusViewModel bluetoothStatusViewModel;
  final CarCommand? activeCommand;
  final VoidCallback onToggleBluetoothConnection;
  final VoidCallback onForward;
  final VoidCallback onStop;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onBackward;

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
            'Capa preparada para enviar comandos a un auto real por Bluetooth. '
            'Ahora funciona en modo simulado para validar la UI y la arquitectura.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          BluetoothStatusPanel(
            viewModel: bluetoothStatusViewModel,
            onToggleConnection: onToggleBluetoothConnection,
          ),
          const SizedBox(height: 16),
          ManualCarControlPanel(
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
