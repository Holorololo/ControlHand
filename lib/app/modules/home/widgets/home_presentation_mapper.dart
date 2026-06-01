import '../../../data/models/auto_state.dart';
import '../controllers/home_controller.dart';
import 'home_presentation_models.dart';
import 'home_widget_support.dart';

class HomePresentationMapper {
  const HomePresentationMapper({required this.controller, required this.state});

  final HomeController controller;
  final AutoState state;

  ConnectionStatusViewModel get connectionStatus {
    final statusLabel = controller.statusLabel;

    return ConnectionStatusViewModel(
      statusLabel: statusLabel,
      statusTone: connectionTone(controller.connectionStatus.value),
      intro: controller.connectionIntro,
      isMobileClient: controller.isMobileClient,
      phoneCameraStatusLabel: controller.phoneCameraStatusLabel,
      phoneCameraTone: cameraTone(controller.mobileCameraStatus.value),
      backendStatusLabel: controller.backendStatusLabel,
      backendStatusTone: backendTone(controller.backendStatusLabel),
      endpointLabel: controller.endpointLabel,
      connectionHint: controller.connectionHint,
      backendActionHint: controller.backendActionHint,
      isConnecting: controller.isConnecting,
      isConnected: controller.isConnected,
      canRestartManagedBackend: controller.canRestartManagedBackend,
    );
  }

  BackendStatusViewModel get backendStatus {
    return BackendStatusViewModel(
      command: controller.backendCommand,
      recentLog: controller.backendRecentLog.value,
      infoMessage: controller.backendInfoMessage.value,
      statePreview: controller.statePreview,
    );
  }

  HandStatusViewModel get handStatus {
    return HandStatusViewModel(
      summary: controller.handSummary,
      cameraStatusLabel: controller.phoneCameraStatusLabel,
      cameraTone: cameraTone(controller.mobileCameraStatus.value),
      cameraSummary: controller.cameraSummary,
      mobileCameraInfoMessage: controller.mobileCameraInfoMessage.value,
      fingersUp: state.fingersUp,
      carMoving: state.carMoving,
      packetLabel: controller.packetLabel,
    );
  }

  CarStatusViewModel get carStatus {
    return CarStatusViewModel(
      movementLabel: controller.movementLabel,
      carMoving: state.carMoving,
      fingersUp: state.fingersUp,
      speed: state.speed,
      handState: state.handState,
      carProgress: state.carProgress,
      errorMessage: controller.errorMessage.value,
    );
  }

  ProcessedPreviewViewModel get processedPreview {
    return ProcessedPreviewViewModel(
      handDetected: state.handDetected,
      cameraSummary: controller.cameraSummary,
      previewAspectRatio: state.previewAspectRatio,
      hasCameraPreview: state.hasCameraPreview,
      previewBytes: state.previewBytes,
    );
  }
}
