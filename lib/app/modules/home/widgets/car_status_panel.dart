import 'package:flutter/material.dart';

import 'home_presentation_models.dart';
import 'home_widget_support.dart';

class CarStatusPanel extends StatelessWidget {
  const CarStatusPanel({required this.viewModel, super.key});

  final CarStatusViewModel viewModel;

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
                      'Estado del auto',
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
                      'Estado del auto',
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
          const SizedBox(height: 16),
          _TrackScene(viewModel: viewModel),
          if (viewModel.errorMessage.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            AlertStrip(message: viewModel.errorMessage),
          ],
        ],
      ),
    );
  }
}

class CarStatusMetricPanel extends StatelessWidget {
  const CarStatusMetricPanel({required this.viewModel, super.key});

  final CarStatusViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return MiniMetric(label: 'Auto', value: viewModel.movementLabel);
  }
}

class _TrackScene extends StatelessWidget {
  const _TrackScene({required this.viewModel});

  final CarStatusViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SurfaceFrame(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LayoutBuilder(
            builder: (context, constraints) {
              final compactWidth = constraints.maxWidth < 360;
              final itemWidth = compactWidth
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 20) / 3;

              // Let metrics wrap before the track does to avoid flex overflow.
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  SizedBox(
                    width: itemWidth,
                    child: MiniMetric(
                      label: 'Dedos',
                      value: viewModel.fingersValue,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: MiniMetric(
                      label: 'Velocidad',
                      value: viewModel.speedValue,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: MiniMetric(
                      label: 'Estado',
                      value: viewModel.handStateLabel,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          const RoadStrip(),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment(-1 + (viewModel.carProgress * 2), 0),
            child: CyberCar(moving: viewModel.isMoving),
          ),
        ],
      ),
    );
  }
}
