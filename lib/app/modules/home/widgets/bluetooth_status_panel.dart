import 'package:flutter/material.dart';

import 'home_presentation_models.dart';
import 'home_widget_support.dart';

class BluetoothStatusPanel extends StatelessWidget {
  const BluetoothStatusPanel({
    required this.viewModel,
    required this.onToggleConnection,
    required this.onSelectAutoVirtualMode,
    required this.onSelectBuzzerRealMode,
    required this.onSelectDevice,
    required this.onRefreshDevices,
    super.key,
  });

  final BluetoothStatusViewModel viewModel;
  final VoidCallback onToggleConnection;
  final VoidCallback onSelectAutoVirtualMode;
  final VoidCallback onSelectBuzzerRealMode;
  final ValueChanged<String?> onSelectDevice;
  final VoidCallback onRefreshDevices;

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
                label: viewModel.transportModeLabel,
                tone: viewModel.transportModeTone,
              ),
              StatusDotChip(
                label: viewModel.outputModeLabel,
                tone: viewModel.outputModeTone,
              ),
              SoftChip(label: 'Ultimo comando ${viewModel.lastCommandLabel}'),
              SoftChip(label: 'Payload ${viewModel.lastPayloadLabel}'),
              SoftChip(label: 'Conexion ${viewModel.connectedDeviceLabel}'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Dispositivos emparejados',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: viewModel.isLoadingDevices ? null : onRefreshDevices,
                tooltip: 'Refrescar dispositivos',
                icon: viewModel.isLoadingDevices
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: viewModel.selectedDeviceAddress,
            isExpanded: true,
            items: viewModel.deviceOptions
                .map(
                  (device) => DropdownMenuItem<String>(
                    value: device.address,
                    child: Text(
                      device.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: viewModel.hasPairedDevices ? onSelectDevice : null,
            decoration: InputDecoration(
              labelText: 'Modulo HC-05 / HC-06',
              helperText: viewModel.deviceSelectionHint,
            ),
          ),
          if (viewModel.deviceErrorLabel.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            AlertStrip(message: viewModel.deviceErrorLabel),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ChoiceChip(
                label: const Text('Auto virtual'),
                selected: !viewModel.isBuzzerOutputMode,
                onSelected: (_) => onSelectAutoVirtualMode(),
              ),
              ChoiceChip(
                label: const Text('Buzzer real'),
                selected: viewModel.isBuzzerOutputMode,
                onSelected: (_) => onSelectBuzzerRealMode(),
              ),
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
