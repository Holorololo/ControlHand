import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'hand_status_panel.dart';
import 'home_presentation_models.dart';
import 'home_widget_support.dart';

class MobilePreviewPanel extends StatelessWidget {
  const MobilePreviewPanel({
    required this.cameraController,
    required this.cameraWaitingMessage,
    required this.handStatusViewModel,
    super.key,
  });

  final CameraController? cameraController;
  final String cameraWaitingMessage;
  final HandStatusViewModel handStatusViewModel;

  @override
  Widget build(BuildContext context) {
    final previewReady =
        cameraController != null && cameraController!.value.isInitialized;

    return PanelShell(
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
              LiveCameraFill(controller: cameraController!)
            else
              CameraWaitingSurface(
                title: 'Camara lista para arrancar',
                message: cameraWaitingMessage,
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
              child: HandStatusPanel(viewModel: handStatusViewModel),
            ),
            const Positioned.fill(child: IgnorePointer(child: TargetReticle())),
          ],
        ),
      ),
    );
  }
}

class ProcessedPreviewPanel extends StatelessWidget {
  const ProcessedPreviewPanel({required this.viewModel, super.key});

  final ProcessedPreviewViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return PanelShell(
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
              StatusDotChip(
                label: viewModel.statusLabel,
                tone: viewModel.statusTone,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.cameraSummary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: viewModel.previewAspectRatio,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[Color(0xFF071226), Color(0xFF02050E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: viewModel.hasCameraPreview
                    ? PreviewImage(bytes: viewModel.previewBytes!)
                    : const CameraWaitingSurface(
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

class _TopOverlayBar extends StatelessWidget {
  const _TopOverlayBar();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        GlassTag(icon: Icons.smartphone_rounded, label: 'Camara del celular'),
        Spacer(),
        GlassTag(icon: Icons.blur_on_rounded, label: 'Neon Vision'),
      ],
    );
  }
}
