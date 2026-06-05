import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import 'diagnostic_panel.dart';
import 'home_presentation_models.dart';
import 'home_widget_support.dart';

class BackendStatusPanel extends StatelessWidget {
  const BackendStatusPanel({required this.viewModel, super.key});

  final BackendStatusViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return PanelShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Backend en la computadora',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          SelectableText(
            viewModel.command,
            style: const TextStyle(
              color: AppTheme.primarySoft,
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          SurfaceTile(title: 'Log reciente', body: viewModel.recentLogMessage),
          const SizedBox(height: 14),
          DiagnosticPanel(statePreview: viewModel.statePreview),
          if (viewModel.observabilitySummary.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            SurfaceTile(
              title: 'Observabilidad',
              body: viewModel.observabilitySummary,
              monospace: true,
            ),
          ],
        ],
      ),
    );
  }
}
