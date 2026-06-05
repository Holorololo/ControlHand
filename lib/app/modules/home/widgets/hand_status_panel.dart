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
              MetricBadge(label: 'Comando', value: viewModel.commandValue),
              MetricBadge(label: 'Payload', value: viewModel.payloadValue),
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
    final handTone = _handTone;
    final outputLabel = _outputLabel;
    final outputTone = _outputTone;

    return RepaintBoundary(
      child: GlassPanel(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            StatusDotChip(label: viewModel.summary, tone: handTone),
            StatusDotChip(
              label: 'Dedos ${viewModel.fingersValue}',
              tone: HomeTone.soft,
            ),
            if (outputLabel != null)
              StatusDotChip(label: outputLabel, tone: outputTone),
          ],
        ),
      ),
    );
  }

  HomeTone get _handTone {
    final normalized = viewModel.summary.trim().toLowerCase();
    if (normalized.contains('abierta') || normalized.contains('open')) {
      return HomeTone.good;
    }
    if (normalized.contains('cerrada') || normalized.contains('closed')) {
      return HomeTone.warn;
    }
    return HomeTone.soft;
  }

  String? get _outputLabel {
    if (bluetoothStatusViewModel == null) {
      return null;
    }
    if (_normalizedPayload.isEmpty) {
      return viewModel.commandValue;
    }
    return '${viewModel.commandValue} / $_normalizedPayload';
  }

  HomeTone get _outputTone {
    final bluetoothViewModel = bluetoothStatusViewModel;
    if (bluetoothViewModel == null) {
      return HomeTone.soft;
    }
    if (!bluetoothViewModel.isBuzzerOutputMode) {
      return bluetoothViewModel.outputModeTone;
    }
    return switch (_normalizedPayload) {
      'S' => HomeTone.alert,
      'H' => HomeTone.warn,
      _ => HomeTone.good,
    };
  }

  String get _normalizedPayload {
    final payload = bluetoothStatusViewModel?.lastPayloadLabel.trim() ?? '';
    if (payload.isEmpty || payload == 'Sin payload') {
      return '';
    }
    return payload;
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
