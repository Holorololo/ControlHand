import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_theme.dart';
import '../controllers/home_controller.dart';
import 'backend_status_panel.dart';
import 'car_status_panel.dart';
import 'connection_panel.dart';
import 'home_presentation_mapper.dart';
import 'home_presentation_models.dart';
import 'home_widget_support.dart';
import 'mobile_preview_panel.dart';

class DesktopHomeLayout extends StatelessWidget {
  const DesktopHomeLayout({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppTheme.bg,
              Color(0xFF08122B),
              AppTheme.bgSecondary,
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: NeonBackdrop()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 1100;

                  return Obx(() {
                    final state = controller.effectiveState;
                    final presentation =
                        HomePresentationMapper.fromHomeController(
                          controller: controller,
                          state: state,
                        );
                    final connectionViewModel = presentation.connectionStatus;
                    final backendStatusViewModel = presentation.backendStatus;
                    final carStatusViewModel = presentation.carStatus;
                    final previewViewModel = presentation.processedPreview;
                    final packetLabel = controller.packetLabel;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SizedBox(
                                  width: 380,
                                  child: _ControlCenterBody(
                                    connectionViewModel: connectionViewModel,
                                    backendStatusViewModel:
                                        backendStatusViewModel,
                                    carStatusViewModel: carStatusViewModel,
                                    previewViewModel: previewViewModel,
                                    hostTextController:
                                        controller.hostTextController,
                                    portTextController:
                                        controller.portTextController,
                                    onToggleConnection: () {
                                      controller.toggleConnection();
                                    },
                                    onReconnect: () {
                                      controller.connect();
                                    },
                                    onRestartBackend: () {
                                      controller.restartManagedBackend();
                                    },
                                    includeRemotePreview: false,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      _DesktopHero(
                                        connectionViewModel:
                                            connectionViewModel,
                                        packetLabel: packetLabel,
                                      ),
                                      const SizedBox(height: 24),
                                      ProcessedPreviewPanel(
                                        viewModel: previewViewModel,
                                      ),
                                      const SizedBox(height: 24),
                                      CarStatusPanel(
                                        viewModel: carStatusViewModel,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: <Widget>[
                                _DesktopHero(
                                  connectionViewModel: connectionViewModel,
                                  packetLabel: packetLabel,
                                ),
                                const SizedBox(height: 20),
                                _ControlCenterBody(
                                  connectionViewModel: connectionViewModel,
                                  backendStatusViewModel:
                                      backendStatusViewModel,
                                  carStatusViewModel: carStatusViewModel,
                                  previewViewModel: previewViewModel,
                                  hostTextController:
                                      controller.hostTextController,
                                  portTextController:
                                      controller.portTextController,
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
                            ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopHero extends StatelessWidget {
  const _DesktopHero({
    required this.connectionViewModel,
    required this.packetLabel,
  });

  final ConnectionStatusViewModel connectionViewModel;
  final String packetLabel;

  @override
  Widget build(BuildContext context) {
    return PanelShell(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const BrandCluster(compact: false),
          const SizedBox(height: 18),
          Text(
            'Control remoto con estetica cyberpunk y prioridad movil.',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 12),
          Text(
            'Flutter ahora separa el arranque ligero de la camara local del panel avanzado, para bajar consumo y dejar el backend remoto como una capa opcional.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              StatusDotChip(
                label: connectionViewModel.statusLabel,
                tone: connectionViewModel.statusTone,
              ),
              StatusDotChip(
                label: connectionViewModel.backendStatusLabel,
                tone: connectionViewModel.backendStatusTone,
              ),
              SoftChip(label: connectionViewModel.endpointLabel),
              SoftChip(label: 'Ultimo paquete $packetLabel'),
            ],
          ),
        ],
      ),
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
    this.includeRemotePreview = true,
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
  final bool includeRemotePreview;

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
        if (includeRemotePreview) ...<Widget>[
          ProcessedPreviewPanel(viewModel: previewViewModel),
          const SizedBox(height: 18),
          CarStatusPanel(viewModel: carStatusViewModel),
          const SizedBox(height: 18),
        ],
        BackendStatusPanel(viewModel: backendStatusViewModel),
      ],
    );
  }
}
