import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'bindings/app_binding.dart';
import 'modules/home/views/home_view.dart';
import 'theme/app_theme.dart';

class MovilControlApp extends StatelessWidget {
  const MovilControlApp({super.key, this.autoConnect = true});

  final bool autoConnect;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'MovilControl',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialBinding: AppBinding(autoConnect: autoConnect),
      home: const HomeView(),
    );
  }
}
