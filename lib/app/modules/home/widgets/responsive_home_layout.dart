import 'package:flutter/material.dart';

import '../controllers/home_controller.dart';
import 'desktop_home_layout.dart';
import 'mobile_home_layout.dart';

class ResponsiveHomeLayout extends StatelessWidget {
  const ResponsiveHomeLayout({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldUseMobileLayout =
            controller.showImmersiveMobileHome && constraints.maxWidth < 1400;

        return shouldUseMobileLayout
            ? MobileHomeLayout(controller: controller)
            : DesktopHomeLayout(controller: controller);
      },
    );
  }
}
