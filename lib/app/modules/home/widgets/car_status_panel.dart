import 'package:flutter/material.dart';

import '../../../config/performance_config.dart';
import 'home_presentation_models.dart';
import 'home_widget_support.dart';

class CarStatusPanel extends StatelessWidget {
  const CarStatusPanel({
    required this.viewModel,
    required this.bluetoothViewModel,
    super.key,
  });

  final CarStatusViewModel viewModel;
  final BluetoothStatusViewModel bluetoothViewModel;

  @override
  Widget build(BuildContext context) {
    return PanelShell(
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
                      'Estado del auto',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    StatusDotChip(
                      label: viewModel.statusLabel,
                      tone: viewModel.statusTone,
                    ),
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Estado del auto',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(width: 12),
                  StatusDotChip(
                    label: viewModel.statusLabel,
                    tone: viewModel.statusTone,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _TrackScene(
            viewModel: viewModel,
            bluetoothViewModel: bluetoothViewModel,
          ),
          if (viewModel.errorMessage.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            AlertStrip(message: viewModel.errorMessage),
          ],
        ],
      ),
    );
  }
}

class CarStatusMetricPanel extends StatelessWidget {
  const CarStatusMetricPanel({required this.viewModel, super.key});

  final CarStatusViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return MiniMetric(label: 'Auto', value: viewModel.movementLabel);
  }
}

class _TrackScene extends StatelessWidget {
  const _TrackScene({
    required this.viewModel,
    required this.bluetoothViewModel,
  });

  final CarStatusViewModel viewModel;
  final BluetoothStatusViewModel bluetoothViewModel;

  @override
  Widget build(BuildContext context) {
    return SurfaceFrame(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LayoutBuilder(
            builder: (context, constraints) {
              final compactWidth = constraints.maxWidth < 360;
              final itemWidth = compactWidth
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 20) / 3;

              // Let metrics wrap before the track does to avoid flex overflow.
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  SizedBox(
                    width: itemWidth,
                    child: MiniMetric(
                      label: 'Dedos',
                      value: viewModel.fingersValue,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: MiniMetric(
                      label: 'Velocidad',
                      value: viewModel.speedValue,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: MiniMetric(
                      label: 'Estado',
                      value: viewModel.handStateLabel,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          RepaintBoundary(
            child: PerformanceConfig.enableAnimatedCar
                ? _AnimatedTrackScene(viewModel: viewModel)
                : _StaticCommandStatus(
                    viewModel: viewModel,
                    bluetoothViewModel: bluetoothViewModel,
                  ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedTrackScene extends StatelessWidget {
  const _AnimatedTrackScene({required this.viewModel});

  final CarStatusViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const RoadStrip(),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment(-1 + (viewModel.carProgress * 2), 0),
          child: CyberCar(moving: viewModel.isMoving),
        ),
      ],
    );
  }
}

class _StaticCommandStatus extends StatelessWidget {
  const _StaticCommandStatus({
    required this.viewModel,
    required this.bluetoothViewModel,
  });

  final CarStatusViewModel viewModel;
  final BluetoothStatusViewModel bluetoothViewModel;

  @override
  Widget build(BuildContext context) {
    final tone = _statusTone;
    final palette = toneColors(tone);
    final statusIcon = _statusIcon;
    final headline = _headline;
    final helperText = _helperText;
    final animationDuration = Duration(
      milliseconds: PerformanceConfig.enableOptimizedAnimations
          ? PerformanceConfig.uiAnimationDurationMs
          : 0,
    );
    final fastDuration = Duration(
      milliseconds: PerformanceConfig.enableOptimizedAnimations
          ? PerformanceConfig.uiAnimationFastDurationMs
          : 0,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        return AnimatedContainer(
          duration: animationDuration,
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: palette.foreground.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AnimatedSwitcher(
                      duration: fastDuration,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.97,
                              end: 1,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _StatusHeadline(
                        key: ValueKey<String>(
                          '$headline|$helperText|${bluetoothViewModel.lastPayloadLabel}',
                        ),
                        palette: palette,
                        icon: statusIcon,
                        headline: headline,
                        helperText: helperText,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _StatusMetaChips(
                      viewModel: viewModel,
                      bluetoothViewModel: bluetoothViewModel,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: fastDuration,
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(
                                begin: 0.97,
                                end: 1,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _StatusHeadline(
                          key: ValueKey<String>(
                            '$headline|$helperText|${bluetoothViewModel.lastPayloadLabel}',
                          ),
                          palette: palette,
                          icon: statusIcon,
                          headline: headline,
                          helperText: helperText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatusMetaChips(
                        viewModel: viewModel,
                        bluetoothViewModel: bluetoothViewModel,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  HomeTone get _statusTone {
    if (!bluetoothViewModel.isConnected) {
      return HomeTone.alert;
    }
    if (_normalizedPayload == 'H') {
      return HomeTone.warn;
    }
    return viewModel.isMoving ? HomeTone.good : HomeTone.alert;
  }

  IconData get _statusIcon {
    if (!bluetoothViewModel.isConnected) {
      return Icons.bluetooth_disabled_rounded;
    }
    return switch (_normalizedPayload) {
      'F' => Icons.keyboard_double_arrow_up_rounded,
      'B' => Icons.keyboard_double_arrow_down_rounded,
      'L' => Icons.turn_left_rounded,
      'R' => Icons.turn_right_rounded,
      'H' => Icons.campaign_rounded,
      _ => Icons.pause_circle_filled_rounded,
    };
  }

  String get _headline {
    if (!bluetoothViewModel.isConnected) {
      return 'SIN ENLACE';
    }
    if (_normalizedPayload.isEmpty) {
      return 'AUTO EN ESPERA';
    }
    return '${viewModel.commandLabel.toUpperCase()} | ${viewModel.payloadLabel}';
  }

  String get _helperText {
    if (!bluetoothViewModel.isConnected) {
      return 'Conecta Bluetooth para enviar comandos al Arduino o al auto virtual.';
    }
    return 'Ultimo comando ${viewModel.commandLabel} con payload ${viewModel.payloadLabel}.';
  }

  String get _normalizedPayload {
    final payload = viewModel.payloadLabel;
    return payload == 'Sin payload' ? '' : payload;
  }
}

class _StatusHeadline extends StatelessWidget {
  const _StatusHeadline({
    required this.palette,
    required this.icon,
    required this.headline,
    required this.helperText,
    super.key,
  });

  final HomeTonePalette palette;
  final IconData icon;
  final String headline;
  final String helperText;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: palette.foreground.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(color: palette.border),
          ),
          child: Icon(icon, color: palette.foreground, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                headline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                helperText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFD3E7F7),
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusMetaChips extends StatelessWidget {
  const _StatusMetaChips({
    required this.viewModel,
    required this.bluetoothViewModel,
  });

  final CarStatusViewModel viewModel;
  final BluetoothStatusViewModel bluetoothViewModel;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          StatusDotChip(
            label: bluetoothViewModel.connectionLabel,
            tone: bluetoothViewModel.connectionTone,
          ),
          StatusDotChip(
            label: bluetoothViewModel.outputModeLabel,
            tone: bluetoothViewModel.outputModeTone,
          ),
          SoftChip(label: viewModel.commandLabel),
          SoftChip(label: 'Payload ${viewModel.payloadLabel}'),
          SoftChip(label: viewModel.movementLabel),
        ],
      ),
    );
  }
}
