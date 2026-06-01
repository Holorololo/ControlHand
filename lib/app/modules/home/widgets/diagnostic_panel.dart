import 'package:flutter/material.dart';

import 'home_widget_support.dart';

class DiagnosticPanel extends StatelessWidget {
  const DiagnosticPanel({required this.statePreview, super.key});

  final String statePreview;

  @override
  Widget build(BuildContext context) {
    return SurfaceTile(
      title: 'Ultimo estado recibido',
      body: statePreview,
      monospace: true,
    );
  }
}
