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

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  children: <Widget>[
                                    _DesktopHero(controller: controller),
                                    const SizedBox(height: 24),
                                    _ReactiveCarStatusPanel(
                                      controller: controller,
                                    ),
                                    const SizedBox(height: 24),
                                    _ControlCenterBody(
                                      controller: controller,
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
                              ),
                            ],
                          )
                        : Column(
                            children: <Widget>[
                              _DesktopHero(controller: controller),
                              const SizedBox(height: 20),
                              _ControlCenterBody(
                                controller: controller,
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
  const _DesktopHero({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return PanelShell(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
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
            child: const BrandCluster(compact: false),
          ),
          const SizedBox(height: 18),
          Text(
            'Demo final centrada en camara, deteccion por dedos y control del auto.',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 12),
          Text(
            'La app conecta automaticamente con el backend, calcula dedos levantados y deja Bluetooth listo para enviar S, L, R, H, B y F al Arduino.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          _ReactiveDesktopHeroChips(controller: controller),
        ],
      ),
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
    return Obx(() {
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
          _ReactiveProcessedPreviewPanel(controller: controller),
          const SizedBox(height: 18),
          BackendStatusPanel(viewModel: backendStatusViewModel),
        ]);
      }

      return Column(children: children);
    });
  }
}

class _ReactiveDesktopHeroChips extends StatelessWidget {
  const _ReactiveDesktopHeroChips({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final connectionViewModel = HomePresentationMapper.mapConnection(
        controller: controller,
      );
      final packetLabel = controller.packetLabel;

      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          StatusDotChip(
            label: controller.demoBackendStatusLabel,
            tone: connectionViewModel.statusTone,
          ),
          SoftChip(label: controller.demoBackendStatusMessage),
          SoftChip(label: 'Ultimo paquete $packetLabel'),
        ],
      );
    });
  }
}

class _ReactiveProcessedPreviewPanel extends StatelessWidget {
  const _ReactiveProcessedPreviewPanel({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.effectiveState;
      final previewViewModel = HomePresentationMapper.mapProcessedPreview(
        controller: controller,
        state: state,
      );
      return ProcessedPreviewPanel(viewModel: previewViewModel);
    });
  }
}

class _ReactiveCarStatusPanel extends StatelessWidget {
  const _ReactiveCarStatusPanel({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.effectiveState;
      final carStatusViewModel = HomePresentationMapper.mapCar(
        controller: controller,
        state: state,
      );
      final bluetoothStatusViewModel =
          HomePresentationMapper.mapBluetoothStatus(controller: controller);
      return CarStatusPanel(
        viewModel: carStatusViewModel,
        bluetoothViewModel: bluetoothStatusViewModel,
      );
    });
  }
}
