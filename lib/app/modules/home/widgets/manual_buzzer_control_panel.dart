import 'package:flutter/material.dart';

import '../../../config/performance_config.dart';
import '../../../data/enums/buzzer_command.dart';
import '../../../data/mappers/buzzer_command_mapper.dart';
import 'home_widget_support.dart';

class ManualBuzzerControlPanel extends StatelessWidget {
  const ManualBuzzerControlPanel({
    required this.isConnected,
    required this.activeCommand,
    required this.activePayload,
    required this.onTurnOn,
    required this.onTurnOff,
    required this.onBeepTest,
    this.helperMessage = '',
    super.key,
  });

  final bool isConnected;
  final BuzzerCommand? activeCommand;
  final String activePayload;
  final VoidCallback onTurnOn;
  final VoidCallback onTurnOff;
  final VoidCallback onBeepTest;
  final String helperMessage;

  @override
  Widget build(BuildContext context) {
    final animationDuration = Duration(
      milliseconds: PerformanceConfig.enableOptimizedAnimations
          ? PerformanceConfig.uiAnimationFastDurationMs
          : 0,
    );

    return SurfaceFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Control manual del buzzer',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          AnimatedSwitcher(
            duration: animationDuration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: helperMessage.isEmpty
                ? const SizedBox.shrink(key: ValueKey<String>('no-helper'))
                : Padding(
                    key: const ValueKey<String>('helper'),
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      helperMessage,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final buttonWidth = constraints.maxWidth < 340
                  ? (constraints.maxWidth - 10) / 2
                  : 160.0;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _BuzzerCommandButton(
                    width: buttonWidth,
                    command: BuzzerCommand.on,
                    activeCommand: activeCommand,
                    activePayload: activePayload,
                    enabled: isConnected,
                    onPressed: onTurnOn,
                  ),
                  _BuzzerCommandButton(
                    width: buttonWidth,
                    command: BuzzerCommand.off,
                    activeCommand: activeCommand,
                    activePayload: activePayload,
                    enabled: isConnected,
                    onPressed: onTurnOff,
                  ),
                  _BuzzerBeepButton(
                    width: buttonWidth,
                    activePayload: activePayload,
                    enabled: isConnected,
                    onPressed: onBeepTest,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BuzzerCommandButton extends StatelessWidget {
  const _BuzzerCommandButton({
    required this.width,
    required this.command,
    required this.activeCommand,
    required this.activePayload,
    required this.enabled,
    required this.onPressed,
  });

  final double width;
  final BuzzerCommand command;
  final BuzzerCommand? activeCommand;
  final String activePayload;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final active =
        activeCommand == command &&
        (command == BuzzerCommand.on
            ? activePayload == '1'
            : activePayload == '0');
    final label = BuzzerCommandMapper.toVisualText(command);
    final animationDuration = Duration(
      milliseconds: PerformanceConfig.enableOptimizedAnimations
          ? PerformanceConfig.uiAnimationFastDurationMs
          : 0,
    );

    return SizedBox(
      width: width,
      child: AnimatedScale(
        duration: animationDuration,
        curve: Curves.easeOutCubic,
        scale: active ? 1 : 0.985,
        child: AnimatedSwitcher(
          duration: animationDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: active
              ? FilledButton(
                  key: ValueKey<String>('filled-${command.name}'),
                  onPressed: enabled ? onPressed : null,
                  child: Text(label, overflow: TextOverflow.ellipsis),
                )
              : OutlinedButton(
                  key: ValueKey<String>('outlined-${command.name}'),
                  onPressed: enabled ? onPressed : null,
                  child: Text(label, overflow: TextOverflow.ellipsis),
                ),
        ),
      ),
    );
  }
}

class _BuzzerBeepButton extends StatelessWidget {
  const _BuzzerBeepButton({
    required this.width,
    required this.activePayload,
    required this.enabled,
    required this.onPressed,
  });

  final double width;
  final String activePayload;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final active = activePayload == 'B';
    final animationDuration = Duration(
      milliseconds: PerformanceConfig.enableOptimizedAnimations
          ? PerformanceConfig.uiAnimationFastDurationMs
          : 0,
    );

    return SizedBox(
      width: width,
      child: AnimatedScale(
        duration: animationDuration,
        curve: Curves.easeOutCubic,
        scale: active ? 1 : 0.985,
        child: AnimatedSwitcher(
          duration: animationDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: active
              ? FilledButton(
                  key: const ValueKey<String>('filled-beep'),
                  onPressed: enabled ? onPressed : null,
                  child: const Text(
                    'Beep test',
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : OutlinedButton(
                  key: const ValueKey<String>('outlined-beep'),
                  onPressed: enabled ? onPressed : null,
                  child: const Text(
                    'Beep test',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
        ),
      ),
    );
  }
}
