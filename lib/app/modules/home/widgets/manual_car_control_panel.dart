import 'package:flutter/material.dart';

import '../../../data/enums/car_command.dart';
import '../../../data/mappers/car_command_mapper.dart';
import 'home_widget_support.dart';

class ManualCarControlPanel extends StatelessWidget {
  const ManualCarControlPanel({
    required this.isConnected,
    required this.activeCommand,
    required this.onForward,
    required this.onStop,
    required this.onLeft,
    required this.onRight,
    required this.onBackward,
    super.key,
  });

  final bool isConnected;
  final CarCommand? activeCommand;
  final VoidCallback onForward;
  final VoidCallback onStop;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onBackward;

  @override
  Widget build(BuildContext context) {
    return SurfaceFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Control manual',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _CommandButton(
                command: CarCommand.forward,
                activeCommand: activeCommand,
                enabled: isConnected,
                onPressed: onForward,
              ),
              _CommandButton(
                command: CarCommand.stop,
                activeCommand: activeCommand,
                enabled: isConnected,
                onPressed: onStop,
              ),
              _CommandButton(
                command: CarCommand.left,
                activeCommand: activeCommand,
                enabled: isConnected,
                onPressed: onLeft,
              ),
              _CommandButton(
                command: CarCommand.right,
                activeCommand: activeCommand,
                enabled: isConnected,
                onPressed: onRight,
              ),
              _CommandButton(
                command: CarCommand.backward,
                activeCommand: activeCommand,
                enabled: isConnected,
                onPressed: onBackward,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommandButton extends StatelessWidget {
  const _CommandButton({
    required this.command,
    required this.activeCommand,
    required this.enabled,
    required this.onPressed,
  });

  final CarCommand command;
  final CarCommand? activeCommand;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final active = activeCommand == command;
    final label = CarCommandMapper.toVisualText(command);

    return SizedBox(
      width: 132,
      child: active
          ? FilledButton(
              onPressed: enabled ? onPressed : null,
              child: Text(label),
            )
          : OutlinedButton(
              onPressed: enabled ? onPressed : null,
              child: Text(label),
            ),
    );
  }
}
