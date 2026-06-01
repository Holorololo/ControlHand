import 'package:get/get.dart';

import '../modules/home/controllers/bluetooth_controller.dart';
import '../modules/home/controllers/connection_controller.dart';
import '../modules/home/controllers/drive_session_controller.dart';
import '../modules/home/controllers/home_controller.dart';
import '../services/auto_state_polling_service.dart';
import '../services/backend_process_service.dart';
import '../services/bluetooth_command_service.dart';
import '../services/mobile_camera_relay_service.dart';
import '../services/mock_bluetooth_command_service.dart';

class AppBinding extends Bindings {
  AppBinding({required this.autoConnect});

  final bool autoConnect;

  @override
  void dependencies() {
    Get.lazyPut<AutoStatePollingService>(() => AutoStatePollingService());
    Get.lazyPut<BackendProcessService>(() => BackendProcessService());
    Get.lazyPut<MobileCameraRelayService>(() => MobileCameraRelayService());
    Get.lazyPut<MockBluetoothCommandService>(
      () => MockBluetoothCommandService(),
    );
    Get.lazyPut<BluetoothCommandService>(
      () => Get.find<MockBluetoothCommandService>(),
    );
    Get.lazyPut<BluetoothController>(() => BluetoothController());
    Get.lazyPut<ConnectionController>(
      () => ConnectionController(autoConnect: autoConnect),
    );
    Get.lazyPut<DriveSessionController>(() => DriveSessionController());
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
