import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_theme.dart';
import '../controllers/home_controller.dart';
import 'backend_status_panel.dart';
import 'car_command_panel.dart';
import 'car_status_panel.dart';
import 'connection_panel.dart';
import 'control_buttons_panel.dart';
import 'hand_status_panel.dart';
import 'home_presentation_mapper.dart';
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
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                    child: Row(
                      children: <Widget>[
                        const Expanded(child: BrandCluster(compact: false)),
                        _ReactiveConnectionStatusChip(controller: controller),
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
                      child: _ReactiveMobilePreview(controller: controller),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                    child: _MobileCommandDeck(
                      controller: controller,
                      onOpenPanel: () => _openControlCenter(context),
                      onToggleConnection: () {
                        controller.toggleConnection();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileCommandDeck extends StatelessWidget {
  const _MobileCommandDeck({
    required this.controller,
    required this.onOpenPanel,
    required this.onToggleConnection,
  });

  final HomeController controller;
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
              Expanded(child: _ReactiveHandMetricPanel(controller: controller)),
              const SizedBox(width: 12),
              Expanded(child: _ReactiveCarMetricPanel(controller: controller)),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final connectionViewModel = HomePresentationMapper.mapConnection(
              controller: controller,
            );
            return MobilePrimaryActionsPanel(
              viewModel: connectionViewModel,
              onToggleConnection: onToggleConnection,
              onOpenPanel: onOpenPanel,
            );
          }),
          _ReactiveCarAlertStrip(controller: controller),
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
          child: ListView(
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
                controller: controller,
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
          ),
        );
      },
    );
  }
}

class _ControlCenterBody extends StatelessWidget {
  const _ControlCenterBody({
    required this.controller,
    required this.hostTextController,
    required this.portTextController,
    required this.onToggleConnection,
    required this.onReconnect,
    required this.onRestartBackend,
  });

  final HomeController controller;
  final TextEditingController hostTextController;
  final TextEditingController portTextController;
  final VoidCallback onToggleConnection;
  final VoidCallback onReconnect;
  final VoidCallback onRestartBackend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Obx(() {
          final connectionViewModel = HomePresentationMapper.mapConnection(
            controller: controller,
          );
          return ConnectionPanel(
            viewModel: connectionViewModel,
            hostTextController: hostTextController,
            portTextController: portTextController,
            onToggleConnection: onToggleConnection,
            onReconnect: onReconnect,
            onRestartBackend: onRestartBackend,
          );
        }),
        const SizedBox(height: 18),
        Obx(() {
          final state = controller.effectiveState;
          final previewViewModel = HomePresentationMapper.mapProcessedPreview(
            controller: controller,
            state: state,
          );
          return ProcessedPreviewPanel(viewModel: previewViewModel);
        }),
        const SizedBox(height: 18),
        Obx(() {
          final state = controller.effectiveState;
          final carStatusViewModel = HomePresentationMapper.mapCar(
            controller: controller,
            state: state,
          );
          return CarStatusPanel(viewModel: carStatusViewModel);
        }),
        const SizedBox(height: 18),
        Obx(() {
          final bluetoothStatusViewModel =
              HomePresentationMapper.mapBluetoothStatus(controller: controller);
          return CarCommandPanel(
            bluetoothStatusViewModel: bluetoothStatusViewModel,
            activeCommand: controller.lastBluetoothCommand.value,
            onToggleBluetoothConnection: () {
              controller.toggleBluetoothConnection();
            },
            onForward: () {
              controller.sendForward();
            },
            onStop: () {
              controller.sendStop();
            },
            onLeft: () {
              controller.sendLeft();
            },
            onRight: () {
              controller.sendRight();
            },
            onBackward: () {
              controller.sendBackward();
            },
          );
        }),
        const SizedBox(height: 18),
        Obx(() {
          final backendStatusViewModel = HomePresentationMapper.mapBackend(
            controller: controller,
          );
          return BackendStatusPanel(viewModel: backendStatusViewModel);
        }),
      ],
    );
  }
}

class _ReactiveConnectionStatusChip extends StatelessWidget {
  const _ReactiveConnectionStatusChip({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final connectionViewModel = HomePresentationMapper.mapConnection(
        controller: controller,
      );
      return StatusDotChip(
        label: connectionViewModel.statusLabel,
        tone: connectionViewModel.statusTone,
      );
    });
  }
}

class _ReactiveMobilePreview extends StatelessWidget {
  const _ReactiveMobilePreview({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.effectiveState;
      final handStatusViewModel = HomePresentationMapper.mapHand(
        controller: controller,
        state: state,
      );
      return MobilePreviewPanel(
        cameraController: controller.phoneCameraController,
        cameraWaitingMessage: controller.mobileCameraInfoMessage.value,
        handStatusViewModel: handStatusViewModel,
      );
    });
  }
}

class _ReactiveHandMetricPanel extends StatelessWidget {
  const _ReactiveHandMetricPanel({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.effectiveState;
      final handStatusViewModel = HomePresentationMapper.mapHand(
        controller: controller,
        state: state,
      );
      return HandStatusMetricPanel(viewModel: handStatusViewModel);
    });
  }
}

class _ReactiveCarMetricPanel extends StatelessWidget {
  const _ReactiveCarMetricPanel({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.effectiveState;
      final carStatusViewModel = HomePresentationMapper.mapCar(
        controller: controller,
        state: state,
      );
      return CarStatusMetricPanel(viewModel: carStatusViewModel);
    });
  }
}

class _ReactiveCarAlertStrip extends StatelessWidget {
  const _ReactiveCarAlertStrip({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.effectiveState;
      final carStatusViewModel = HomePresentationMapper.mapCar(
        controller: controller,
        state: state,
      );

      if (carStatusViewModel.errorMessage.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        children: <Widget>[
          const SizedBox(height: 12),
          AlertStrip(message: carStatusViewModel.errorMessage),
        ],
      );
    });
  }
}
