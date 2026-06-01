import 'package:flutter/material.dart';

import 'home_presentation_models.dart';

class ConnectionActionButtonsPanel extends StatelessWidget {
  const ConnectionActionButtonsPanel({
    required this.viewModel,
    required this.onToggleConnection,
    required this.onReconnect,
    required this.onRestartBackend,
    super.key,
  });

  final ConnectionStatusViewModel viewModel;
  final VoidCallback onToggleConnection;
  final VoidCallback onReconnect;
  final VoidCallback onRestartBackend;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        FilledButton(
          onPressed: viewModel.isConnecting ? null : onToggleConnection,
          child: Text(viewModel.primaryActionLabel),
        ),
        OutlinedButton(onPressed: onReconnect, child: const Text('Reconectar')),
        OutlinedButton(
          onPressed: viewModel.canRestartManagedBackend
              ? onRestartBackend
              : null,
          child: const Text('Reiniciar backend'),
        ),
      ],
    );
  }
}

class MobilePrimaryActionsPanel extends StatelessWidget {
  const MobilePrimaryActionsPanel({
    required this.viewModel,
    required this.onToggleConnection,
    required this.onOpenPanel,
    super.key,
  });

  final ConnectionStatusViewModel viewModel;
  final VoidCallback onToggleConnection;
  final VoidCallback onOpenPanel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: FilledButton.icon(
            onPressed: viewModel.isConnecting ? null : onToggleConnection,
            icon: Icon(viewModel.primaryActionIcon),
            label: Text(viewModel.primaryActionLabel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onOpenPanel,
            icon: const Icon(Icons.dashboard_customize_rounded),
            label: const Text('Panel'),
          ),
        ),
      ],
    );
  }
}
