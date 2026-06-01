import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/auto_state.dart';
import '../../../services/auto_socket_service.dart';
import '../../../services/mobile_camera_relay_service.dart';
import '../../../theme/app_theme.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return controller.showImmersiveMobileHome
        ? _MobileHome(controller: controller)
        : _DesktopHome(controller: controller);
  }
}

class _MobileHome extends StatelessWidget {
  const _MobileHome({required this.controller});

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
            const Positioned.fill(child: _NeonBackdrop()),
            SafeArea(
              child: Obx(() {
                final state = controller.effectiveState;

                return Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                      child: Row(
                        children: <Widget>[
                          const Expanded(child: _BrandCluster(compact: false)),
                          _StatusDotChip(
                            label: controller.statusLabel,
                            tone: _connectionTone(
                              controller.connectionStatus.value,
                            ),
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
                        child: _PhoneCameraStage(
                          controller: controller,
                          state: state,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      child: _MobileCommandDeck(
                        controller: controller,
                        state: state,
                        onOpenPanel: () => _openControlCenter(context),
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

class _DesktopHome extends StatelessWidget {
  const _DesktopHome({required this.controller});

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
            const Positioned.fill(child: _NeonBackdrop()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 1100;

                  return Obx(() {
                    final state = controller.effectiveState;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SizedBox(
                                  width: 380,
                                  child: _ControlCenterBody(
                                    controller: controller,
                                    state: state,
                                    includeRemotePreview: false,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      _DesktopHero(controller: controller),
                                      const SizedBox(height: 24),
                                      _BackendPreviewCard(
                                        state: state,
                                        cameraSummary: controller.cameraSummary,
                                      ),
                                      const SizedBox(height: 24),
                                      _TrackCard(
                                        state: state,
                                        errorMessage:
                                            controller.errorMessage.value,
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
                                  state: state,
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
  const _DesktopHero({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _BrandCluster(compact: false),
          const SizedBox(height: 18),
          Text(
            'Control remoto con estética cyberpunk y prioridad móvil.',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 12),
          Text(
            'Flutter ahora separa el arranque ligero de la cámara local del panel avanzado, para bajar consumo y dejar el backend remoto como una capa opcional.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _StatusDotChip(
                label: controller.statusLabel,
                tone: _connectionTone(controller.connectionStatus.value),
              ),
              _StatusDotChip(
                label: controller.backendStatusLabel,
                tone: _backendTone(controller.backendStatusLabel),
              ),
              _SoftChip(label: controller.endpointLabel),
              _SoftChip(label: 'Ultimo paquete ${controller.packetLabel}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhoneCameraStage extends StatelessWidget {
  const _PhoneCameraStage({required this.controller, required this.state});

  final HomeController controller;
  final AutoState state;

  @override
  Widget build(BuildContext context) {
    final cameraController = controller.phoneCameraController;
    final previewReady =
        cameraController != null && cameraController.value.isInitialized;

    return _PanelShell(
      padding: EdgeInsets.zero,
      radius: 30,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFF071430), Color(0xFF030712)],
                ),
              ),
            ),
            if (previewReady)
              _LiveCameraFill(controller: cameraController)
            else
              _CameraWaitingSurface(
                title: 'Camara lista para arrancar',
                message: controller.mobileCameraInfoMessage.value,
                icon: Icons.videocam_rounded,
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.black.withValues(alpha: 0.18),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.62),
                    ],
                    stops: const <double>[0, 0.45, 1],
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 26,
              left: 22,
              right: 22,
              child: _TopOverlayBar(),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: _BottomOverlayCard(controller: controller, state: state),
            ),
            const Positioned.fill(
              child: IgnorePointer(child: _TargetReticle()),
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
    required this.state,
    required this.onOpenPanel,
  });

  final HomeController controller;
  final AutoState state;
  final VoidCallback onOpenPanel;

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      padding: const EdgeInsets.all(18),
      radius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _MiniMetric(
                  label: 'Gesto',
                  value: controller.handSummary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniMetric(
                  label: 'Auto',
                  value: controller.movementLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: controller.isConnecting
                      ? null
                      : controller.toggleConnection,
                  icon: Icon(
                    controller.isConnected
                        ? Icons.link_off_rounded
                        : Icons.wifi_tethering_rounded,
                  ),
                  label: Text(
                    controller.isConnected ? 'Desconectar' : 'Conectar',
                  ),
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
          ),
          if (controller.errorMessage.value.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _AlertStrip(message: controller.errorMessage.value),
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
                    const Expanded(child: _BrandCluster(compact: true)),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _ControlCenterBody(controller: controller, state: state),
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
    required this.controller,
    required this.state,
    this.includeRemotePreview = true,
  });

  final HomeController controller;
  final AutoState state;
  final bool includeRemotePreview;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _PanelShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Centro de control',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                controller.connectionIntro,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller.hostTextController,
                decoration: InputDecoration(
                  labelText: 'Host',
                  helperText: controller.isMobileClient
                      ? 'Usa la IP LAN de tu PC o adb reverse'
                      : '127.0.0.1 usa tu backend local',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.portTextController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Puerto',
                  helperText: 'El backend remoto escucha en 5000 por defecto',
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton(
                    onPressed: controller.isConnecting
                        ? null
                        : controller.toggleConnection,
                    child: Text(
                      controller.isConnected ? 'Desconectar' : 'Conectar',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: controller.connect,
                    child: const Text('Reconectar'),
                  ),
                  OutlinedButton(
                    onPressed: controller.canRestartManagedBackend
                        ? controller.restartManagedBackend
                        : null,
                    child: const Text('Reiniciar backend'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _StatusDotChip(
                    label: controller.phoneCameraStatusLabel,
                    tone: _cameraTone(controller.mobileCameraStatus.value),
                  ),
                  _StatusDotChip(
                    label: controller.backendStatusLabel,
                    tone: _backendTone(controller.backendStatusLabel),
                  ),
                  _SoftChip(label: controller.endpointLabel),
                ],
              ),
              const SizedBox(height: 16),
              _SurfaceTile(
                title: 'Como conectarte',
                body: controller.connectionHint,
              ),
              const SizedBox(height: 12),
              _SurfaceTile(
                title: 'Accion recomendada',
                body: controller.backendActionHint,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (includeRemotePreview) ...<Widget>[
          _BackendPreviewCard(
            state: state,
            cameraSummary: controller.cameraSummary,
          ),
          const SizedBox(height: 18),
          _TrackCard(state: state, errorMessage: controller.errorMessage.value),
          const SizedBox(height: 18),
        ],
        _PanelShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Backend en la computadora',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              SelectableText(
                controller.backendCommand,
                style: const TextStyle(
                  color: AppTheme.primarySoft,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              _SurfaceTile(
                title: 'Log reciente',
                body: controller.backendRecentLog.value.isEmpty
                    ? (controller.backendInfoMessage.value.isEmpty
                          ? 'Sin eventos recientes del proceso Python.'
                          : controller.backendInfoMessage.value)
                    : controller.backendRecentLog.value,
              ),
              const SizedBox(height: 14),
              _SurfaceTile(
                title: 'Ultimo estado recibido',
                body: controller.statePreview,
                monospace: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackendPreviewCard extends StatelessWidget {
  const _BackendPreviewCard({required this.state, required this.cameraSummary});

  final AutoState state;
  final String cameraSummary;

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Preview procesado',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              _StatusDotChip(
                label: state.handDetected
                    ? 'Seguimiento activo'
                    : 'Esperando mano',
                tone: state.handDetected ? _Tone.good : _Tone.soft,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(cameraSummary, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: state.previewAspectRatio,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[Color(0xFF071226), Color(0xFF02050E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: state.hasCameraPreview
                    ? _PreviewImage(bytes: state.previewBytes!)
                    : const _CameraWaitingSurface(
                        title: 'Preview remoto en espera',
                        message:
                            'El backend aun no envio la primera imagen procesada.',
                        icon: Icons.radar_rounded,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({required this.state, required this.errorMessage});

  final AutoState state;
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Estado del auto',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              _StatusDotChip(
                label: state.carMoving ? 'GO' : 'STOP',
                tone: state.carMoving ? _Tone.good : _Tone.alert,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TrackScene(state: state),
          if (errorMessage.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            _AlertStrip(message: errorMessage),
          ],
        ],
      ),
    );
  }
}

class _TrackScene extends StatelessWidget {
  const _TrackScene({required this.state});

  final AutoState state;

  @override
  Widget build(BuildContext context) {
    return _SurfaceFrame(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _MiniMetric(label: 'Dedos', value: '${state.fingersUp}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(label: 'Velocidad', value: '${state.speed}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(label: 'Estado', value: state.handState),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _RoadStrip(),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment(-1 + (state.carProgress * 2), 0),
            child: _CyberCar(moving: state.carMoving),
          ),
        ],
      ),
    );
  }
}

class _TopOverlayBar extends StatelessWidget {
  const _TopOverlayBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const <Widget>[
        _GlassTag(icon: Icons.smartphone_rounded, label: 'Camara del celular'),
        Spacer(),
        _GlassTag(icon: Icons.blur_on_rounded, label: 'Neon Vision'),
      ],
    );
  }
}

class _BottomOverlayCard extends StatelessWidget {
  const _BottomOverlayCard({required this.controller, required this.state});

  final HomeController controller;
  final AutoState state;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  controller.handSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _StatusDotChip(
                label: controller.phoneCameraStatusLabel,
                tone: _cameraTone(controller.mobileCameraStatus.value),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            controller.mobileCameraInfoMessage.value.isEmpty
                ? controller.cameraSummary
                : controller.mobileCameraInfoMessage.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _MetricBadge(label: 'Dedos', value: '${state.fingersUp}'),
              _MetricBadge(
                label: 'Auto',
                value: state.carMoving ? 'AVANZA' : 'STOP',
              ),
              _MetricBadge(label: 'Paquete', value: controller.packetLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _NeonBackdrop extends StatelessWidget {
  const _NeonBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned(
          top: -80,
          left: -50,
          child: _GlowOrb(
            size: 240,
            color: AppTheme.primary.withValues(alpha: 0.16),
          ),
        ),
        Positioned(
          top: 140,
          right: -30,
          child: _GlowOrb(
            size: 180,
            color: AppTheme.secondary.withValues(alpha: 0.18),
          ),
        ),
        Positioned(
          bottom: -100,
          left: 40,
          child: _GlowOrb(
            size: 260,
            color: AppTheme.primarySoft.withValues(alpha: 0.12),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _GridPainter())),
        ),
      ],
    );
  }
}

class _BrandCluster extends StatelessWidget {
  const _BrandCluster({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _GlassTag(
          icon: Icons.memory_rounded,
          label: compact ? 'MOVILCONTROL' : 'MOVILCONTROL // NEON DRIVE',
        ),
        SizedBox(height: compact ? 10 : 12),
        Text(
          compact ? 'Panel remoto' : 'Cámara, gestos y backend remoto',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontSize: compact ? 20 : 28),
        ),
      ],
    );
  }
}

class _LiveCameraFill extends StatelessWidget {
  const _LiveCameraFill({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    final width = previewSize?.height ?? 720;
    final height = previewSize?.width ?? 1280;

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: width,
        height: height,
        child: CameraPreview(controller),
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
  }
}

class _CameraWaitingSurface extends StatelessWidget {
  const _CameraWaitingSurface({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.24),
                ),
              ),
              child: Icon(icon, color: AppTheme.primarySoft, size: 40),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message.isEmpty
                  ? 'Preparando el flujo de camara para el modo remoto.'
                  : message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetReticle extends StatelessWidget {
  const _TargetReticle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.32),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 48,
                height: 2,
                color: AppTheme.primary.withValues(alpha: 0.55),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 48,
                height: 2,
                color: AppTheme.primary.withValues(alpha: 0.55),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 2,
                height: 48,
                color: AppTheme.primary.withValues(alpha: 0.55),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 2,
                height: 48,
                color: AppTheme.primary.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _SurfaceFrame(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.stroke),
      ),
      child: RichText(
        text: TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: '$label ',
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceTile extends StatelessWidget {
  const _SurfaceTile({
    required this.title,
    required this.body,
    this.monospace = false,
  });

  final String title;
  final String body;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return _SurfaceFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SelectableText(
            body,
            style: TextStyle(
              color: monospace ? AppTheme.primarySoft : AppTheme.muted,
              height: 1.5,
              fontSize: 13.5,
              fontFamily: monospace ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertStrip extends StatelessWidget {
  const _AlertStrip({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFFFB4C8),
          fontSize: 13,
          height: 1.45,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GlassTag extends StatelessWidget {
  const _GlassTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: AppTheme.primarySoft, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDotChip extends StatelessWidget {
  const _StatusDotChip({required this.label, required this.tone});

  final String label;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.foreground,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colors.foreground.withValues(alpha: 0.45),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Text(
            label,
            style: TextStyle(
              color: colors.text,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.stroke),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.muted,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppTheme.stroke),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
          const BoxShadow(
            color: Color(0x60000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.stroke),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x68000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SurfaceFrame extends StatelessWidget {
  const _SurfaceFrame({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.panelStrong,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.stroke),
      ),
      child: child,
    );
  }
}

class _RoadStrip extends StatelessWidget {
  const _RoadStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFF111419),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List<Widget>.generate(
            6,
            (_) => Container(
              width: 28,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.text.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CyberCar extends StatelessWidget {
  const _CyberCar({required this.moving});

  final bool moving;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 280),
      offset: moving ? Offset.zero : const Offset(-0.02, 0),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 280),
        scale: moving ? 1 : 0.97,
        child: SizedBox(
          width: 112,
          height: 58,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: 18,
                right: 18,
                top: 0,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 12,
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                bottom: -2,
                child: _WheelGlow(moving: moving),
              ),
              Positioned(
                right: 14,
                bottom: -2,
                child: _WheelGlow(moving: moving),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WheelGlow extends StatelessWidget {
  const _WheelGlow({required this.moving});

  final bool moving;

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      duration: const Duration(milliseconds: 260),
      turns: moving ? 0.12 : 0,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF05070D),
          border: Border.all(color: AppTheme.primarySoft, width: 2),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    const spacing = 42.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _Tone { good, warn, alert, soft }

_Tone _connectionTone(SocketConnectionStatus status) {
  return switch (status) {
    SocketConnectionStatus.connected => _Tone.good,
    SocketConnectionStatus.connecting => _Tone.warn,
    SocketConnectionStatus.disconnected => _Tone.alert,
  };
}

_Tone _cameraTone(MobileCameraRelayStatus status) {
  return switch (status) {
    MobileCameraRelayStatus.streaming => _Tone.good,
    MobileCameraRelayStatus.ready => _Tone.soft,
    MobileCameraRelayStatus.initializing => _Tone.warn,
    MobileCameraRelayStatus.failed => _Tone.alert,
    MobileCameraRelayStatus.permissionDenied => _Tone.alert,
    MobileCameraRelayStatus.idle => _Tone.soft,
    MobileCameraRelayStatus.unsupported => _Tone.alert,
  };
}

_Tone _backendTone(String label) {
  if (label.contains('Fallo') || label.contains('inactivo')) {
    return _Tone.alert;
  }
  if (label.contains('Buscando') || label.contains('Iniciando')) {
    return _Tone.warn;
  }
  if (label.contains('externo')) {
    return _Tone.soft;
  }
  return _Tone.good;
}

class _TonePalette {
  const _TonePalette({
    required this.background,
    required this.border,
    required this.foreground,
    required this.text,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final Color text;
}

_TonePalette _toneColors(_Tone tone) {
  return switch (tone) {
    _Tone.good => const _TonePalette(
      background: Color(0x142AF5B3),
      border: Color(0x332AF5B3),
      foreground: AppTheme.success,
      text: Color(0xFFD7FFF4),
    ),
    _Tone.warn => const _TonePalette(
      background: Color(0x14FFC857),
      border: Color(0x33FFC857),
      foreground: AppTheme.warning,
      text: Color(0xFFFFF2CC),
    ),
    _Tone.alert => const _TonePalette(
      background: Color(0x14FF5D8F),
      border: Color(0x33FF5D8F),
      foreground: AppTheme.danger,
      text: Color(0xFFFFDCE8),
    ),
    _Tone.soft => const _TonePalette(
      background: Color(0x1200D9FF),
      border: Color(0x3300D9FF),
      foreground: AppTheme.primarySoft,
      text: AppTheme.text,
    ),
  };
}
