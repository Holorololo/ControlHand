import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'modules/home/controllers/home_controller.dart';
import 'modules/home/views/home_view.dart';
import 'services/auto_socket_service.dart';
import 'services/backend_process_service.dart';
import 'services/mobile_camera_relay_service.dart';
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
      initialBinding: BindingsBuilder(() {
        if (!Get.isRegistered<AutoSocketService>()) {
          Get.put(AutoSocketService(), permanent: true);
        }

        if (!Get.isRegistered<BackendProcessService>()) {
          Get.put(BackendProcessService(), permanent: true);
        }

        if (!Get.isRegistered<MobileCameraRelayService>()) {
          Get.put(MobileCameraRelayService(), permanent: true);
        }

        if (!Get.isRegistered<HomeController>()) {
          Get.put(
            HomeController(
              Get.find<AutoSocketService>(),
              Get.find<BackendProcessService>(),
              mobileCameraRelayService: Get.find<MobileCameraRelayService>(),
              autoConnect: autoConnect,
            ),
          );
        }
      }),
      home: const HomeView(),
    );
  }
}
