import 'package:flutter/material.dart';

import 'home_presentation_models.dart';
import 'home_widget_support.dart';

class BluetoothStatusPanel extends StatelessWidget {
  const BluetoothStatusPanel({
    required this.viewModel,
    required this.onToggleConnection,
    super.key,
  });

  final BluetoothStatusViewModel viewModel;
  final VoidCallback onToggleConnection;

  @override
  Widget build(BuildContext context) {
    return SurfaceFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Estado Bluetooth',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              StatusDotChip(
                label: viewModel.connectionLabel,
                tone: viewModel.connectionTone,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              StatusDotChip(
                label: viewModel.modeLabel,
                tone: viewModel.modeTone,
              ),
              SoftChip(label: 'Ultimo comando ${viewModel.lastCommandLabel}'),
              SoftChip(label: 'Payload ${viewModel.lastPayloadLabel}'),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onToggleConnection,
            child: Text(viewModel.toggleActionLabel),
          ),
        ],
      ),
    );
  }
}
