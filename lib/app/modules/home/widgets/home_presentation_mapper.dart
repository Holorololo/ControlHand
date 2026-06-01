import '../../../data/models/auto_state.dart';
import '../../../services/auto_state_polling_service.dart';
import '../../../services/mobile_camera_relay_service.dart';
import '../controllers/home_controller.dart';
import 'home_presentation_models.dart';
import 'home_widget_support.dart';

class HomePresentationInput {
  const HomePresentationInput({
    required this.state,
    required this.connectionStatus,
    required this.mobileCameraStatus,
    required this.statusLabel,
    required this.connectionIntro,
    required this.isMobileClient,
    required this.phoneCameraStatusLabel,
    required this.backendStatusLabel,
    required this.endpointLabel,
    required this.connectionHint,
    required this.backendActionHint,
    required this.isConnecting,
    required this.isConnected,
    required this.canRestartManagedBackend,
    required this.backendCommand,
    required this.backendRecentLog,
    required this.backendInfoMessage,
    required this.statePreview,
    required this.handSummary,
    required this.cameraSummary,
    required this.mobileCameraInfoMessage,
    required this.packetLabel,
    required this.movementLabel,
    required this.errorMessage,
  });

  factory HomePresentationInput.fromHomeController({
    required HomeController controller,
    required AutoState state,
  }) {
    return HomePresentationInput(
      state: state,
      connectionStatus: controller.connectionStatus.value,
      mobileCameraStatus: controller.mobileCameraStatus.value,
      statusLabel: controller.statusLabel,
      connectionIntro: controller.connectionIntro,
      isMobileClient: controller.isMobileClient,
      phoneCameraStatusLabel: controller.phoneCameraStatusLabel,
      backendStatusLabel: controller.backendStatusLabel,
      endpointLabel: controller.endpointLabel,
      connectionHint: controller.connectionHint,
      backendActionHint: controller.backendActionHint,
      isConnecting: controller.isConnecting,
      isConnected: controller.isConnected,
      canRestartManagedBackend: controller.canRestartManagedBackend,
      backendCommand: controller.backendCommand,
      backendRecentLog: controller.backendRecentLog.value,
      backendInfoMessage: controller.backendInfoMessage.value,
      statePreview: controller.statePreview,
      handSummary: controller.handSummary,
      cameraSummary: controller.cameraSummary,
      mobileCameraInfoMessage: controller.mobileCameraInfoMessage.value,
      packetLabel: controller.packetLabel,
      movementLabel: controller.movementLabel,
      errorMessage: controller.errorMessage.value,
    );
  }

  final AutoState state;
  final SocketConnectionStatus connectionStatus;
  final MobileCameraRelayStatus mobileCameraStatus;
  final String statusLabel;
  final String connectionIntro;
  final bool isMobileClient;
  final String phoneCameraStatusLabel;
  final String backendStatusLabel;
  final String endpointLabel;
  final String connectionHint;
  final String backendActionHint;
  final bool isConnecting;
  final bool isConnected;
  final bool canRestartManagedBackend;
  final String backendCommand;
  final String backendRecentLog;
  final String backendInfoMessage;
  final String statePreview;
  final String handSummary;
  final String cameraSummary;
  final String mobileCameraInfoMessage;
  final String packetLabel;
  final String movementLabel;
  final String errorMessage;
}

class HomePresentationMapper {
  const HomePresentationMapper({required HomePresentationInput input})
    : _input = input;

  factory HomePresentationMapper.fromHomeController({
    required HomeController controller,
    required AutoState state,
  }) {
    return HomePresentationMapper(
      input: HomePresentationInput.fromHomeController(
        controller: controller,
        state: state,
      ),
    );
  }

  final HomePresentationInput _input;

  ConnectionStatusViewModel get connectionStatus {
    final statusLabel = _input.statusLabel;

    return ConnectionStatusViewModel(
      statusLabel: statusLabel,
      statusTone: connectionTone(_input.connectionStatus),
      intro: _input.connectionIntro,
      isMobileClient: _input.isMobileClient,
      phoneCameraStatusLabel: _input.phoneCameraStatusLabel,
      phoneCameraTone: cameraTone(_input.mobileCameraStatus),
      backendStatusLabel: _input.backendStatusLabel,
      backendStatusTone: backendTone(_input.backendStatusLabel),
      endpointLabel: _input.endpointLabel,
      connectionHint: _input.connectionHint,
      backendActionHint: _input.backendActionHint,
      isConnecting: _input.isConnecting,
      isConnected: _input.isConnected,
      canRestartManagedBackend: _input.canRestartManagedBackend,
    );
  }

  BackendStatusViewModel get backendStatus {
    return BackendStatusViewModel(
      command: _input.backendCommand,
      recentLog: _input.backendRecentLog,
      infoMessage: _input.backendInfoMessage,
      statePreview: _input.statePreview,
    );
  }

  HandStatusViewModel get handStatus {
    return HandStatusViewModel(
      summary: _input.handSummary,
      cameraStatusLabel: _input.phoneCameraStatusLabel,
      cameraTone: cameraTone(_input.mobileCameraStatus),
      cameraSummary: _input.cameraSummary,
      mobileCameraInfoMessage: _input.mobileCameraInfoMessage,
      fingersUp: _input.state.fingersUp,
      carMoving: _input.state.carMoving,
      packetLabel: _input.packetLabel,
    );
  }

  CarStatusViewModel get carStatus {
    return CarStatusViewModel(
      movementLabel: _input.movementLabel,
      carMoving: _input.state.carMoving,
      fingersUp: _input.state.fingersUp,
      speed: _input.state.speed,
      handState: _input.state.handState,
      carProgress: _input.state.carProgress,
      errorMessage: _input.errorMessage,
    );
  }

  ProcessedPreviewViewModel get processedPreview {
    return ProcessedPreviewViewModel(
      handDetected: _input.state.handDetected,
      cameraSummary: _input.cameraSummary,
      previewAspectRatio: _input.state.previewAspectRatio,
      hasCameraPreview: _input.state.hasCameraPreview,
      previewBytes: _input.state.previewBytes,
    );
  }
}
