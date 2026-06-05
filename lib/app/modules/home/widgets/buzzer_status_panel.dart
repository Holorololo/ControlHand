import 'package:flutter/material.dart';

import '../../../config/performance_config.dart';
import '../../../data/enums/car_command.dart';
import '../../../data/mappers/car_command_mapper.dart';
import 'home_presentation_models.dart';
import 'home_widget_support.dart';

class BuzzerStatusPanel extends StatelessWidget {
  const BuzzerStatusPanel({
    required this.viewModel,
    required this.activeCommand,
    super.key,
  });

  final BluetoothStatusViewModel viewModel;
  final CarCommand? activeCommand;

  @override
  Widget build(BuildContext context) {
    final tone = _statusTone;
    final palette = toneColors(tone);
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

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: animationDuration,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.border),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: palette.foreground.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 360;

                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Resumen rapido',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      StatusDotChip(label: _headline, tone: tone),
                    ],
                  );
                }

                return Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Resumen rapido',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    StatusDotChip(label: _headline, tone: tone),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 420;
                final headline = _headline;
                final detail = _detail;
                final statusKey =
                    '$headline|$detail|${viewModel.lastPayloadLabel}|${activeCommand?.name ?? 'none'}';

                return stacked
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
                                    begin: 0.96,
                                    end: 1,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: _CommandHeadline(
                              key: ValueKey<String>(statusKey),
                              palette: palette,
                              icon: _statusIcon,
                              headline: headline,
                              detail: detail,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _CommandMetaWrap(viewModel: viewModel),
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
                                      begin: 0.96,
                                      end: 1,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: _CommandHeadline(
                                key: ValueKey<String>(statusKey),
                                palette: palette,
                                icon: _statusIcon,
                                headline: headline,
                                detail: detail,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _CommandMetaWrap(viewModel: viewModel),
                          ),
                        ],
                      );
              },
            ),
            const SizedBox(height: 12),
            if (viewModel.manualBuzzerControlHint.isNotEmpty)
              SoftChip(label: viewModel.manualBuzzerControlHint),
          ],
        ),
      ),
    );
  }

  CarCommand? get _resolvedCommand {
    if (activeCommand != null) {
      return activeCommand;
    }

    final label = viewModel.lastCommandLabel.trim();
    if (label.isEmpty || label == 'Sin comando') {
      return null;
    }

    final payload = viewModel.lastPayloadLabel.trim();
    return CarCommandMapper.fromPayload(payload) ??
        CarCommandMapper.fromBackendCommand(label.toLowerCase());
  }

  HomeTone get _statusTone {
    if (!viewModel.isConnected) {
      return HomeTone.alert;
    }
    if (!viewModel.isBuzzerOutputMode) {
      return HomeTone.soft;
    }
    return switch (_resolvedCommand) {
      CarCommand.horn => HomeTone.warn,
      CarCommand.stop => HomeTone.alert,
      _ => HomeTone.good,
    };
  }

  IconData get _statusIcon {
    if (!viewModel.isConnected) {
      return Icons.bluetooth_disabled_rounded;
    }
    if (!viewModel.isBuzzerOutputMode) {
      return Icons.route_rounded;
    }
    return switch (_resolvedCommand) {
      CarCommand.left => Icons.turn_left_rounded,
      CarCommand.right => Icons.turn_right_rounded,
      CarCommand.backward => Icons.keyboard_double_arrow_down_rounded,
      CarCommand.horn => Icons.campaign_rounded,
      CarCommand.forward => Icons.keyboard_double_arrow_up_rounded,
      _ => Icons.pause_circle_filled_rounded,
    };
  }

  String get _headline {
    if (!viewModel.isConnected) {
      return 'Bluetooth desconectado';
    }
    if (!viewModel.isBuzzerOutputMode) {
      return 'Modo virtual activo';
    }
    final command = _resolvedCommand;
    if (command == null) {
      return 'Esperando comando';
    }
    return '${CarCommandMapper.toVisualText(command)} | ${viewModel.lastPayloadLabel}';
  }

  String get _detail {
    if (!viewModel.isConnected) {
      return 'Conecta el HC-05/HC-06 para poder enviar S, L, R, H, B y F al Arduino.';
    }
    if (!viewModel.isBuzzerOutputMode) {
      return 'El backend sigue mostrando el auto virtual. Cambia a auto real cuando quieras enviar comandos al Arduino.';
    }
    final command = _resolvedCommand;
    if (command == null) {
      return 'Esperando la primera deteccion de dedos para calcular el payload.';
    }
    return 'Comando ${CarCommandMapper.toVisualText(command)} con payload ${viewModel.lastPayloadLabel}.';
  }
}

class _CommandHeadline extends StatelessWidget {
  const _CommandHeadline({
    required this.palette,
    required this.icon,
    required this.headline,
    required this.detail,
    super.key,
  });

  final HomeTonePalette palette;
  final IconData icon;
  final String headline;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: palette.foreground.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(color: palette.border),
          ),
          child: Icon(icon, color: palette.foreground, size: 26),
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
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detail,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFD3E7F7),
                  fontSize: 13,
                  height: 1.4,
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

class _CommandMetaWrap extends StatelessWidget {
  const _CommandMetaWrap({required this.viewModel});

  final BluetoothStatusViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          StatusDotChip(
            label: viewModel.connectionLabel,
            tone: viewModel.connectionTone,
          ),
          StatusDotChip(
            label: viewModel.outputModeLabel,
            tone: viewModel.outputModeTone,
          ),
          SoftChip(label: 'Payload ${viewModel.lastPayloadLabel}'),
          SoftChip(label: viewModel.lastCommandLabel),
          SoftChip(label: viewModel.connectedDeviceLabel),
        ],
      ),
    );
  }
}
