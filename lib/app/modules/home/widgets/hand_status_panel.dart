import 'package:flutter/material.dart';

import '../../../config/performance_config.dart';
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
    final fingerCount = viewModel.fingersValue;
    final command = viewModel.commandValue;
    final payload = _normalizedPayload;
    final btConnected = bluetoothStatusViewModel?.isConnected ?? false;

    final animDuration = Duration(
      milliseconds: PerformanceConfig.enableOptimizedAnimations
          ? PerformanceConfig.uiAnimationFastDurationMs
          : 0,
    );

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.52),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.stroke.withValues(alpha: 0.5)),
        ),
        child: AnimatedSwitcher(
          duration: animDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Wrap(
            key: ValueKey<String>(
              '$fingerCount|$command|$payload|$btConnected',
            ),
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: <Widget>[
              _OverlayChip(
                icon: Icons.fingerprint_rounded,
                label: fingerCount,
                tone: _fingerTone,
              ),
              _OverlayChip(
                icon: _commandIcon,
                label: command,
                tone: HomeTone.soft,
              ),
              _OverlayChip(
                icon: Icons.send_rounded,
                label: payload.isNotEmpty ? payload : '-',
                tone: HomeTone.soft,
              ),
              _BluetoothDot(connected: btConnected),
            ],
          ),
        ),
      ),
    );
  }

  HomeTone get _fingerTone {
    final count = int.tryParse(viewModel.fingersValue) ?? 0;
    if (count >= 5) return HomeTone.good;
    if (count <= 0) return HomeTone.warn;
    return HomeTone.soft;
  }

  IconData get _commandIcon {
    return switch (viewModel.commandValue) {
      'Adelante' => Icons.keyboard_double_arrow_up_rounded,
      'Atrás' || 'Atras' => Icons.keyboard_double_arrow_down_rounded,
      'Izquierda' => Icons.turn_left_rounded,
      'Derecha' => Icons.turn_right_rounded,
      'Bocina' => Icons.campaign_rounded,
      _ => Icons.pause_circle_filled_rounded,
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

class _OverlayChip extends StatelessWidget {
  const _OverlayChip({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final HomeTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = toneColors(tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: palette.foreground, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: palette.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BluetoothDot extends StatelessWidget {
  const _BluetoothDot({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppTheme.success : AppTheme.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            connected
                ? Icons.bluetooth_connected_rounded
                : Icons.bluetooth_disabled_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: <BoxShadow>[
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
              ],
            ),
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
