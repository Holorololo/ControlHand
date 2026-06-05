import 'package:flutter/material.dart';

import '../../../data/enums/buzzer_command.dart';
import '../../../data/mappers/buzzer_command_mapper.dart';
import 'home_widget_support.dart';

class ManualBuzzerControlPanel extends StatelessWidget {
  const ManualBuzzerControlPanel({
    required this.isConnected,
    required this.activeCommand,
    required this.onTurnOn,
    required this.onTurnOff,
    super.key,
  });

  final bool isConnected;
  final BuzzerCommand? activeCommand;
  final VoidCallback onTurnOn;
  final VoidCallback onTurnOff;

  @override
  Widget build(BuildContext context) {
    return SurfaceFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Control manual del buzzer',
            style: Theme.of(context).textTheme.titleMedium,
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
                    enabled: isConnected,
                    onPressed: onTurnOn,
                  ),
                  _BuzzerCommandButton(
                    width: buttonWidth,
                    command: BuzzerCommand.off,
                    activeCommand: activeCommand,
                    enabled: isConnected,
                    onPressed: onTurnOff,
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
    required this.enabled,
    required this.onPressed,
  });

  final double width;
  final BuzzerCommand command;
  final BuzzerCommand? activeCommand;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final active = activeCommand == command;
    final label = BuzzerCommandMapper.toVisualText(command);

    return SizedBox(
      width: width,
      child: active
          ? FilledButton(
              onPressed: enabled ? onPressed : null,
              child: Text(label, overflow: TextOverflow.ellipsis),
            )
          : OutlinedButton(
              onPressed: enabled ? onPressed : null,
              child: Text(label, overflow: TextOverflow.ellipsis),
            ),
    );
  }
}
