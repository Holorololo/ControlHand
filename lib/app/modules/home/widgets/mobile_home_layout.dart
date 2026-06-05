import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_theme.dart';
import '../controllers/home_controller.dart';
import 'backend_status_panel.dart';
import 'car_command_panel.dart';
import 'car_status_panel.dart';
import 'connection_panel.dart';
import 'home_presentation_mapper.dart';
import 'home_widget_support.dart';
import 'mobile_preview_panel.dart';

class MobileHomeLayout extends StatelessWidget {
  const MobileHomeLayout({required this.controller, super.key});

  final HomeController controller;

  Future<void> _openControlCenter(BuildContext context) async {
    await controller.openControlCenter();
    if (!context.mounted) {
      controller.closeControlCenter();
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
      controller.closeControlCenter();
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
                    child: _MobileTopBar(
                      controller: controller,
                      onOpenPanel: () => _openControlCenter(context),
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
  });

  final HomeController controller;
  final VoidCallback onOpenPanel;

  @override
  Widget build(BuildContext context) {
    return PanelShell(
      padding: const EdgeInsets.all(18),
      radius: 26,
      child: Obx(() {
        final bluetoothStatusViewModel =
            HomePresentationMapper.mapBluetoothStatus(controller: controller);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                StatusDotChip(
                  label: controller.demoBackendStatusLabel,
                  tone: connectionTone(controller.connectionStatus.value),
                ),
                StatusDotChip(
                  label: bluetoothStatusViewModel.connectionLabel,
                  tone: bluetoothStatusViewModel.connectionTone,
                ),
                SoftChip(
                  label: 'Payload ${bluetoothStatusViewModel.lastPayloadLabel}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              controller.demoBackendStatusMessage,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpenPanel,
                icon: const Icon(Icons.bluetooth_searching_rounded),
                label: const Text(
                  'Bluetooth y control',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        );
      }),
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
          final developerMode = controller.isDeveloperModeEnabled.value;
          final bluetoothStatusViewModel =
              HomePresentationMapper.mapBluetoothStatus(controller: controller);
          final children = <Widget>[
            CarCommandPanel(
              bluetoothStatusViewModel: bluetoothStatusViewModel,
              activeCommand: controller.lastBluetoothCommand.value,
              activePayload: controller.lastBluetoothPayload.value,
              onToggleBluetoothConnection: () {
                controller.toggleBluetoothConnection();
              },
              onSelectAutoVirtualMode: () {
                controller.enableAutoVirtualBluetoothMode();
              },
              onSelectBuzzerRealMode: () {
                controller.enableBuzzerRealBluetoothMode();
              },
              onSelectBluetoothDevice: (address) {
                controller.selectBluetoothDevice(address);
              },
              onRefreshBluetoothDevices: () {
                controller.refreshPairedBluetoothDevices();
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
              onHorn: () {
                controller.sendHorn();
              },
              developerMode: developerMode,
            ),
          ];

          if (developerMode) {
            final connectionViewModel = HomePresentationMapper.mapConnection(
              controller: controller,
            );
            final state = controller.effectiveState;
            final previewViewModel = HomePresentationMapper.mapProcessedPreview(
              controller: controller,
              state: state,
            );
            final carStatusViewModel = HomePresentationMapper.mapCar(
              controller: controller,
              state: state,
            );
            final backendStatusViewModel = HomePresentationMapper.mapBackend(
              controller: controller,
            );

            children.addAll(<Widget>[
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Modo desarrollador'),
              ),
              const SizedBox(height: 12),
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
              CarStatusPanel(
                viewModel: carStatusViewModel,
                bluetoothViewModel: bluetoothStatusViewModel,
              ),
              const SizedBox(height: 18),
              BackendStatusPanel(viewModel: backendStatusViewModel),
            ]);
          }

          return Column(children: children);
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
      return StatusDotChip(
        label: controller.demoBackendStatusLabel,
        tone: connectionTone(controller.connectionStatus.value),
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
      final bluetoothStatusViewModel =
          HomePresentationMapper.mapBluetoothStatus(controller: controller);
      return MobilePreviewPanel(
        cameraController: controller.phoneCameraController,
        cameraWaitingMessage: controller.mobileCameraInfoMessage.value,
        handStatusViewModel: handStatusViewModel,
        bluetoothStatusViewModel: bluetoothStatusViewModel,
      );
    });
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({required this.controller, required this.onOpenPanel});

  final HomeController controller;
  final VoidCallback onOpenPanel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 380;
        final actionButton = IconButton.filledTonal(
          onPressed: onOpenPanel,
          onLongPress: controller.canUseDeveloperMode
              ? () {
                  controller.toggleDeveloperMode();
                  Get.snackbar(
                    'Modo desarrollador',
                    controller.isDeveloperModeEnabled.value
                        ? 'Se activaron los paneles tecnicos.'
                        : 'Se ocultaron los paneles tecnicos.',
                    snackPosition: SnackPosition.BOTTOM,
                    margin: const EdgeInsets.all(16),
                  );
                }
              : null,
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.panelStrong,
            foregroundColor: AppTheme.primarySoft,
          ),
          icon: const Icon(Icons.bluetooth_audio_rounded),
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const BrandCluster(compact: false),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _ReactiveConnectionStatusChip(
                        controller: controller,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  actionButton,
                ],
              ),
            ],
          );
        }

        return Row(
          children: <Widget>[
            const Expanded(child: BrandCluster(compact: false)),
            _ReactiveConnectionStatusChip(controller: controller),
            const SizedBox(width: 10),
            actionButton,
          ],
        );
      },
    );
  }
}
