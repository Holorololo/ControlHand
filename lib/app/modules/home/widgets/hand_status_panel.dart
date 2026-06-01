import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import 'home_presentation_models.dart';
import 'home_widget_support.dart';

class HandStatusPanel extends StatelessWidget {
  const HandStatusPanel({
    required this.viewModel,
    this.bluetoothStatusViewModel,
    this.compact = false,
    super.key,
  });

  final HandStatusViewModel viewModel;
  final BluetoothStatusViewModel? bluetoothStatusViewModel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactHandStatusPanel(
        viewModel: viewModel,
        bluetoothStatusViewModel: bluetoothStatusViewModel,
      );
    }

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  viewModel.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              StatusDotChip(
                label: viewModel.cameraStatusLabel,
                tone: viewModel.cameraTone,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.detailMessage,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              MetricBadge(label: 'Dedos', value: viewModel.fingersValue),
              MetricBadge(label: 'Auto', value: viewModel.carValue),
              MetricBadge(label: 'Paquete', value: viewModel.packetLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactHandStatusPanel extends StatelessWidget {
  const _CompactHandStatusPanel({
    required this.viewModel,
    required this.bluetoothStatusViewModel,
  });

  final HandStatusViewModel viewModel;
  final BluetoothStatusViewModel? bluetoothStatusViewModel;

  @override
  Widget build(BuildContext context) {
    final payloadLabel = bluetoothStatusViewModel?.lastPayloadLabel;
    final commandText = bluetoothStatusViewModel?.lastCommandLabel;
    final commandLabel = bluetoothStatusViewModel == null
        ? null
        : '${payloadLabel == null || payloadLabel == 'Sin payload' ? '--' : payloadLabel} / '
              '${commandText == null || commandText == 'Sin comando' ? 'espera' : commandText}';

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              StatusDotChip(
                label: viewModel.summary,
                tone: viewModel.cameraTone,
              ),
              StatusDotChip(
                label: viewModel.cameraStatusLabel,
                tone: viewModel.cameraTone,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              MetricBadge(label: 'Dedos', value: viewModel.fingersValue),
              MetricBadge(label: 'Auto', value: viewModel.carValue),
              MetricBadge(label: 'Paquete', value: viewModel.packetLabel),
              if (commandLabel != null)
                MetricBadge(label: 'Cmd', value: commandLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class HandStatusMetricPanel extends StatelessWidget {
  const HandStatusMetricPanel({required this.viewModel, super.key});

  final HandStatusViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return MiniMetric(label: 'Gesto', value: viewModel.summary);
  }
}
