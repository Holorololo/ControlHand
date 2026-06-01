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
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 320;

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Estado Bluetooth',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    StatusDotChip(
                      label: viewModel.connectionLabel,
                      tone: viewModel.connectionTone,
                    ),
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Estado Bluetooth',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  StatusDotChip(
                    label: viewModel.connectionLabel,
                    tone: viewModel.connectionTone,
                  ),
                ],
              );
            },
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
