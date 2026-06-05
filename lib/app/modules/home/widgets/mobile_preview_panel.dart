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
    required this.bluetoothStatusViewModel,
    super.key,
  });

  final CameraController? cameraController;
  final String cameraWaitingMessage;
  final HandStatusViewModel handStatusViewModel;
  final BluetoothStatusViewModel bluetoothStatusViewModel;

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
            // Light gradient at top for chip readability, clear center, subtle
            // bottom vignette.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.black.withValues(alpha: 0.42),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.18),
                    ],
                    stops: const <double>[0, 0.18, 0.85, 1],
                  ),
                ),
              ),
            ),
            // Status chips positioned at the top.
            Positioned(
              left: 10,
              right: 10,
              top: 10,
              child: RepaintBoundary(
                child: HandStatusPanel(
                  viewModel: handStatusViewModel,
                  bluetoothStatusViewModel: bluetoothStatusViewModel,
                  compact: true,
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.34),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: const Text(
                      'Pon la mano dentro del marco',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD5EFFF),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 320;

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Preview procesado',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    StatusDotChip(
                      label: viewModel.statusLabel,
                      tone: viewModel.statusTone,
                    ),
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Preview procesado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(width: 12),
                  StatusDotChip(
                    label: viewModel.statusLabel,
                    tone: viewModel.statusTone,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.cameraSummary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
                    ? PreviewImage(
                        bytes: viewModel.previewBytes!,
                        cacheWidth: viewModel.previewCacheWidth,
                        frameId: viewModel.previewFrameId,
                      )
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
