import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_theme.dart';
import '../controllers/home_controller.dart';
import 'backend_status_panel.dart';
import 'car_status_panel.dart';
import 'connection_panel.dart';
import 'control_buttons_panel.dart';
import 'hand_status_panel.dart';
import 'home_presentation_mapper.dart';
import 'home_presentation_models.dart';
import 'home_widget_support.dart';
import 'mobile_preview_panel.dart';

class MobileHomeLayout extends StatelessWidget {
  const MobileHomeLayout({required this.controller, super.key});

  final HomeController controller;

  Future<void> _openControlCenter(BuildContext context) async {
    await controller.openDiagnosticsPanel();
    if (!context.mounted) {
      controller.closeDiagnosticsPanel();
      return;
    }

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _ControlCenterSheet(controller: controller),
      );
    } finally {
      controller.closeDiagnosticsPanel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              AppTheme.bg,
              Color(0xFF071029),
              AppTheme.bgSecondary,
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: NeonBackdrop()),
            SafeArea(
              child: Obx(() {
                final state = controller.effectiveState;
                final presentation = HomePresentationMapper.fromHomeController(
                  controller: controller,
                  state: state,
                );
                final connectionViewModel = presentation.connectionStatus;
                final handStatusViewModel = presentation.handStatus;
                final carStatusViewModel = presentation.carStatus;

                return Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                      child: Row(
                        children: <Widget>[
                          const Expanded(child: BrandCluster(compact: false)),
                          StatusDotChip(
                            label: connectionViewModel.statusLabel,
                            tone: connectionViewModel.statusTone,
                          ),
                          const SizedBox(width: 10),
                          IconButton.filledTonal(
                            onPressed: () => _openControlCenter(context),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.panelStrong,
                              foregroundColor: AppTheme.primarySoft,
                            ),
                            icon: const Icon(Icons.tune_rounded),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: MobilePreviewPanel(
                          cameraController: controller.phoneCameraController,
                          cameraWaitingMessage:
                              controller.mobileCameraInfoMessage.value,
                          handStatusViewModel: handStatusViewModel,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      child: _MobileCommandDeck(
                        connectionViewModel: connectionViewModel,
                        handStatusViewModel: handStatusViewModel,
                        carStatusViewModel: carStatusViewModel,
                        onOpenPanel: () => _openControlCenter(context),
                        onToggleConnection: () {
                          controller.toggleConnection();
                        },
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileCommandDeck extends StatelessWidget {
  const _MobileCommandDeck({
    required this.connectionViewModel,
    required this.handStatusViewModel,
    required this.carStatusViewModel,
    required this.onOpenPanel,
    required this.onToggleConnection,
  });

  final ConnectionStatusViewModel connectionViewModel;
  final HandStatusViewModel handStatusViewModel;
  final CarStatusViewModel carStatusViewModel;
  final VoidCallback onOpenPanel;
  final VoidCallback onToggleConnection;

  @override
  Widget build(BuildContext context) {
    return PanelShell(
      padding: const EdgeInsets.all(18),
      radius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: HandStatusMetricPanel(viewModel: handStatusViewModel),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CarStatusMetricPanel(viewModel: carStatusViewModel),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MobilePrimaryActionsPanel(
            viewModel: connectionViewModel,
            onToggleConnection: onToggleConnection,
            onOpenPanel: onOpenPanel,
          ),
          if (carStatusViewModel.errorMessage.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            AlertStrip(message: carStatusViewModel.errorMessage),
          ],
        ],
      ),
    );
  }
}

class _ControlCenterSheet extends StatelessWidget {
  const _ControlCenterSheet({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.84,
      minChildSize: 0.58,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
            border: Border.all(color: AppTheme.stroke),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0xA0000000),
                blurRadius: 30,
                offset: Offset(0, -10),
              ),
            ],
          ),
          child: Obx(() {
            final state = controller.effectiveState;
            final presentation = HomePresentationMapper.fromHomeController(
              controller: controller,
              state: state,
            );

            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
              children: <Widget>[
                Center(
                  child: Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    const Expanded(child: BrandCluster(compact: true)),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _ControlCenterBody(
                  connectionViewModel: presentation.connectionStatus,
                  backendStatusViewModel: presentation.backendStatus,
                  carStatusViewModel: presentation.carStatus,
                  previewViewModel: presentation.processedPreview,
                  hostTextController: controller.hostTextController,
                  portTextController: controller.portTextController,
                  onToggleConnection: () {
                    controller.toggleConnection();
                  },
                  onReconnect: () {
                    controller.connect();
                  },
                  onRestartBackend: () {
                    controller.restartManagedBackend();
                  },
                ),
              ],
            );
          }),
        );
      },
    );
  }
}

class _ControlCenterBody extends StatelessWidget {
  const _ControlCenterBody({
    required this.connectionViewModel,
    required this.backendStatusViewModel,
    required this.carStatusViewModel,
    required this.previewViewModel,
    required this.hostTextController,
    required this.portTextController,
    required this.onToggleConnection,
    required this.onReconnect,
    required this.onRestartBackend,
  });

  final ConnectionStatusViewModel connectionViewModel;
  final BackendStatusViewModel backendStatusViewModel;
  final CarStatusViewModel carStatusViewModel;
  final ProcessedPreviewViewModel previewViewModel;
  final TextEditingController hostTextController;
  final TextEditingController portTextController;
  final VoidCallback onToggleConnection;
  final VoidCallback onReconnect;
  final VoidCallback onRestartBackend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ConnectionPanel(
          viewModel: connectionViewModel,
          hostTextController: hostTextController,
          portTextController: portTextController,
          onToggleConnection: onToggleConnection,
          onReconnect: onReconnect,
          onRestartBackend: onRestartBackend,
        ),
        const SizedBox(height: 18),
        ProcessedPreviewPanel(viewModel: previewViewModel),
        const SizedBox(height: 18),
        CarStatusPanel(viewModel: carStatusViewModel),
        const SizedBox(height: 18),
        BackendStatusPanel(viewModel: backendStatusViewModel),
      ],
    );
  }
}
