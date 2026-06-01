import 'package:camera/camera.dart';
import 'package:get/get.dart';

import 'package:movilcontrol/app/data/models/auto_state.dart';
import 'package:movilcontrol/app/modules/home/controllers/connection_controller.dart';
import 'package:movilcontrol/app/modules/home/controllers/drive_session_controller.dart';
import 'package:movilcontrol/app/services/auto_state_polling_service.dart';
import 'package:movilcontrol/app/services/backend_process_service.dart';
import 'package:movilcontrol/app/services/mobile_camera_relay_service.dart';

class FakeAutoStatePollingService extends AutoStatePollingService {
  final Rx<SocketConnectionStatus> _status =
      SocketConnectionStatus.disconnected.obs;
  final Rxn<AutoState> _latestState = Rxn<AutoState>();
  final RxString _errorMessage = ''.obs;
  final Rxn<DateTime> _lastPacketAt = Rxn<DateTime>();

  int connectCallCount = 0;
  int disconnectCallCount = 0;
  String? lastConnectHost;
  int? lastConnectPort;
  bool previewStreamingEnabledValue = true;
  final List<bool> previewStreamingToggles = <bool>[];

  @override
  Rx<SocketConnectionStatus> get status => _status;

  @override
  Rxn<AutoState> get latestState => _latestState;

  @override
  RxString get errorMessage => _errorMessage;

  @override
  Rxn<DateTime> get lastPacketAt => _lastPacketAt;

  @override
  bool get previewStreamingEnabled => previewStreamingEnabledValue;

  @override
  Future<void> connect({String? host, int? port}) async {
    connectCallCount++;
    lastConnectHost = host;
    lastConnectPort = port;
    _status.value = SocketConnectionStatus.connected;
  }

  @override
  Future<void> disconnect() async {
    disconnectCallCount++;
    _status.value = SocketConnectionStatus.disconnected;
  }

  @override
  void setPreviewStreamingEnabled(bool enabled) {
    previewStreamingEnabledValue = enabled;
    previewStreamingToggles.add(enabled);
  }
}

class FakeBackendProcessService extends BackendProcessService {
  final Rx<BackendRuntimeStatus> _status = BackendRuntimeStatus.idle.obs;
  final RxString _infoMessage = ''.obs;
  final RxString _recentLog = ''.obs;

  bool canAutoStartValue = true;
  bool canManageHostValue = true;
  int ensureStartedCallCount = 0;
  int stopManagedBackendCallCount = 0;
  String? lastEnsureHost;
  int? lastEnsurePort;

  @override
  Rx<BackendRuntimeStatus> get status => _status;

  @override
  RxString get infoMessage => _infoMessage;

  @override
  RxString get recentLog => _recentLog;

  @override
  bool get canAutoStart => canAutoStartValue;

  @override
  bool canManageHost(String host) => canManageHostValue;

  @override
  Future<void> ensureStarted({
    String host = '127.0.0.1',
    int port = 5000,
  }) async {
    ensureStartedCallCount++;
    lastEnsureHost = host;
    lastEnsurePort = port;
  }

  @override
  Future<void> stopManagedBackend() async {
    stopManagedBackendCallCount++;
  }
}

class FakeMobileCameraRelayService extends MobileCameraRelayService {
  final Rx<MobileCameraRelayStatus> _status = MobileCameraRelayStatus.idle.obs;
  final RxString _infoMessage = ''.obs;

  bool supportedValue = false;
  bool hasPreviewValue = false;
  bool isStreamingValue = false;
  CameraController? controllerValue;
  int preparePreviewCallCount = 0;
  int startRelayCallCount = 0;
  int stopRelayCallCount = 0;
  bool lastStopDisposeCamera = false;
  String? lastStartHost;
  int? lastStartPort;

  @override
  Rx<MobileCameraRelayStatus> get status => _status;

  @override
  RxString get infoMessage => _infoMessage;

  @override
  bool get supported => supportedValue;

  @override
  bool get hasPreview => hasPreviewValue;

  @override
  bool get isStreaming => isStreamingValue;

  @override
  CameraController? get controller => controllerValue;

  @override
  Future<void> preparePreview() async {
    preparePreviewCallCount++;
  }

  @override
  Future<void> startRelay({required String host, required int port}) async {
    startRelayCallCount++;
    lastStartHost = host;
    lastStartPort = port;
    isStreamingValue = true;
    _status.value = MobileCameraRelayStatus.streaming;
  }

  @override
  Future<void> stopRelay({bool disposeCamera = false}) async {
    stopRelayCallCount++;
    lastStopDisposeCamera = disposeCamera;
    isStreamingValue = false;
    _status.value = supportedValue
        ? MobileCameraRelayStatus.ready
        : MobileCameraRelayStatus.unsupported;
  }
}

class TestConnectionController extends ConnectionController {
  TestConnectionController({
    super.autoConnect = false,
    this.isMobileClientOverride,
  });

  final bool? isMobileClientOverride;

  @override
  bool get isMobileClient => isMobileClientOverride ?? super.isMobileClient;
}

class TestDriveSessionController extends DriveSessionController {
  TestDriveSessionController({this.isMobileClientOverride});

  final bool? isMobileClientOverride;

  @override
  bool get isMobileClient => isMobileClientOverride ?? super.isMobileClient;
}
