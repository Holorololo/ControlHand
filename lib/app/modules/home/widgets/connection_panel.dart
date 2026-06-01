import 'package:flutter/material.dart';

import 'control_buttons_panel.dart';
import 'home_presentation_models.dart';
import 'home_widget_support.dart';

class ConnectionPanel extends StatelessWidget {
  const ConnectionPanel({
    required this.viewModel,
    required this.hostTextController,
    required this.portTextController,
    required this.onToggleConnection,
    required this.onReconnect,
    required this.onRestartBackend,
    super.key,
  });

  final ConnectionStatusViewModel viewModel;
  final TextEditingController hostTextController;
  final TextEditingController portTextController;
  final VoidCallback onToggleConnection;
  final VoidCallback onReconnect;
  final VoidCallback onRestartBackend;

  @override
  Widget build(BuildContext context) {
    return PanelShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Centro de control',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(viewModel.intro, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          TextField(
            controller: hostTextController,
            decoration: InputDecoration(
              labelText: 'Host',
              helperText: viewModel.hostHelperText,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: portTextController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Puerto',
              helperText: viewModel.portHelperText,
            ),
          ),
          const SizedBox(height: 16),
          ConnectionActionButtonsPanel(
            viewModel: viewModel,
            onToggleConnection: onToggleConnection,
            onReconnect: onReconnect,
            onRestartBackend: onRestartBackend,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              StatusDotChip(
                label: viewModel.phoneCameraStatusLabel,
                tone: viewModel.phoneCameraTone,
              ),
              StatusDotChip(
                label: viewModel.backendStatusLabel,
                tone: viewModel.backendStatusTone,
              ),
              SoftChip(label: viewModel.endpointLabel),
            ],
          ),
          const SizedBox(height: 16),
          SurfaceTile(title: 'Como conectarte', body: viewModel.connectionHint),
          const SizedBox(height: 12),
          SurfaceTile(
            title: 'Accion recomendada',
            body: viewModel.backendActionHint,
          ),
        ],
      ),
    );
  }
}
