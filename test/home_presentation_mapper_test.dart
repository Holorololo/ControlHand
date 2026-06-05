import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movilcontrol/app/data/models/auto_state.dart';
import 'package:movilcontrol/app/modules/home/widgets/home_presentation_mapper.dart';
import 'package:movilcontrol/app/modules/home/widgets/home_presentation_models.dart';
import 'package:movilcontrol/app/modules/home/widgets/home_widget_support.dart';
import 'package:movilcontrol/app/modules/home/widgets/mobile_preview_panel.dart';
import 'package:movilcontrol/app/services/auto_state_polling_service.dart';
import 'package:movilcontrol/app/services/mobile_camera_relay_service.dart';

void main() {
  group('HomePresentationMapper', () {
    test('maps open hand to the expected visual state', () {
      final mapper = HomePresentationMapper(
        input: _buildInput(
          state: _buildState(
            handDetected: true,
            handState: 'MANO ABIERTA',
            fingersUp: 5,
            carMoving: true,
          ),
          handSummary: 'MANO ABIERTA',
          movementLabel: 'Auto avanzando',
        ),
      );

      final handStatus = mapper.handStatus;

      expect(handStatus.summary, 'MANO ABIERTA');
      expect(handStatus.fingersValue, '5');
      expect(handStatus.carValue, 'AVANZA');
      expect(handStatus.cameraTone, HomeTone.good);
    });

    test('maps closed hand to the expected visual state', () {
      final mapper = HomePresentationMapper(
        input: _buildInput(
          state: _buildState(
            handDetected: true,
            handState: 'MANO CERRADA',
            fingersUp: 0,
            carMoving: false,
          ),
          handSummary: 'MANO CERRADA',
          movementLabel: 'Auto detenido',
          mobileCameraInfoMessage: 'Camara del celular lista',
          mobileCameraStatus: MobileCameraRelayStatus.ready,
        ),
      );

      final handStatus = mapper.handStatus;

      expect(handStatus.summary, 'MANO CERRADA');
      expect(handStatus.fingersValue, '0');
      expect(handStatus.carValue, 'STOP');
      expect(handStatus.detailMessage, 'Camara del celular lista');
      expect(handStatus.cameraTone, HomeTone.soft);
    });

    test('maps no hand detected to the expected visual state', () {
      final mapper = HomePresentationMapper(
        input: _buildInput(
          state: _buildState(
            handDetected: false,
            handState: 'Sin mano',
            fingersUp: 0,
            carMoving: false,
          ),
          handSummary: 'No se detecta mano.',
          movementLabel: 'Auto detenido',
        ),
      );

      final handStatus = mapper.handStatus;

      expect(handStatus.summary, 'No se detecta mano.');
      expect(handStatus.fingersValue, '0');
      expect(handStatus.carValue, 'STOP');
    });

    test('maps moving car to the expected visual state', () {
      final mapper = HomePresentationMapper(
        input: _buildInput(
          state: _buildState(
            handDetected: true,
            handState: 'MANO ABIERTA',
            fingersUp: 5,
            carMoving: true,
            carX: 540,
            speed: 18,
          ),
          movementLabel: 'Auto avanzando',
        ),
      );

      final carStatus = mapper.carStatus;

      expect(carStatus.movementLabel, 'Auto avanzando');
      expect(carStatus.statusLabel, 'GO');
      expect(carStatus.statusTone, HomeTone.good);
      expect(carStatus.speedValue, '18');
      expect(carStatus.isMoving, isTrue);
      expect(carStatus.carProgress, greaterThan(0));
    });

    test('maps stopped car to the expected visual state', () {
      final mapper = HomePresentationMapper(
        input: _buildInput(
          state: _buildState(
            handDetected: false,
            handState: 'Esperando backend',
            fingersUp: 0,
            carMoving: false,
            carX: 0,
            speed: 8,
          ),
          movementLabel: 'Auto detenido',
          errorMessage: 'Sin deteccion de mano',
        ),
      );

      final carStatus = mapper.carStatus;

      expect(carStatus.movementLabel, 'Auto detenido');
      expect(carStatus.statusLabel, 'STOP');
      expect(carStatus.statusTone, HomeTone.alert);
      expect(carStatus.errorMessage, 'Sin deteccion de mano');
      expect(carStatus.isMoving, isFalse);
    });

    test('maps connected backend labels and actions correctly', () {
      final mapper = HomePresentationMapper(
        input: _buildInput(
          connectionStatus: SocketConnectionStatus.connected,
          statusLabel: 'Conectado',
          backendStatusLabel: 'Backend iniciado por Flutter',
          backendRecentLog: 'Backend arriba',
          isConnected: true,
          canRestartManagedBackend: true,
        ),
      );

      final connectionStatus = mapper.connectionStatus;
      final backendStatus = mapper.backendStatus;

      expect(connectionStatus.statusLabel, 'Conectado');
      expect(connectionStatus.statusTone, HomeTone.good);
      expect(
        connectionStatus.backendStatusLabel,
        'Backend iniciado por Flutter',
      );
      expect(connectionStatus.backendStatusTone, HomeTone.good);
      expect(connectionStatus.primaryActionLabel, 'Desconectar');
      expect(backendStatus.recentLogMessage, 'Backend arriba');
    });

    test('maps disconnected backend labels and fallback log correctly', () {
      final mapper = HomePresentationMapper(
        input: _buildInput(
          connectionStatus: SocketConnectionStatus.disconnected,
          statusLabel: 'Desconectado',
          backendStatusLabel: 'Backend inactivo',
          backendRecentLog: '',
          backendInfoMessage: '',
          isConnected: false,
          canRestartManagedBackend: false,
        ),
      );

      final connectionStatus = mapper.connectionStatus;
      final backendStatus = mapper.backendStatus;

      expect(connectionStatus.statusLabel, 'Desconectado');
      expect(connectionStatus.statusTone, HomeTone.alert);
      expect(connectionStatus.backendStatusTone, HomeTone.alert);
      expect(connectionStatus.primaryActionLabel, 'Conectar');
      expect(
        backendStatus.recentLogMessage,
        'Sin eventos recientes del proceso Python.',
      );
    });

    test('builds a valid processed preview view model when preview exists', () {
      final bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);
      final mapper = HomePresentationMapper(
        input: _buildInput(
          state: _buildState(
            handDetected: true,
            handState: 'MANO ABIERTA',
            fingersUp: 5,
            carMoving: true,
            previewBytes: bytes,
            previewWidth: 1280,
            previewHeight: 720,
          ),
        ),
      );

      final preview = mapper.processedPreview;

      expect(preview.hasCameraPreview, isTrue);
      expect(preview.previewBytes, bytes);
      expect(preview.previewFrameId, isNull);
      expect(preview.previewAspectRatio, closeTo(1280 / 720, 0.0001));
      expect(preview.statusLabel, 'Seguimiento activo');
      expect(preview.statusTone, HomeTone.good);
    });

    test('builds a fallback preview view model when preview is missing', () {
      final mapper = HomePresentationMapper(
        input: _buildInput(
          state: _buildState(
            handDetected: false,
            handState: 'Sin mano',
            fingersUp: 0,
            carMoving: false,
            previewBytes: null,
            previewWidth: null,
            previewHeight: null,
          ),
          cameraSummary: 'Esperando primer preview procesado.',
        ),
      );

      final preview = mapper.processedPreview;

      expect(preview.hasCameraPreview, isFalse);
      expect(preview.previewBytes, isNull);
      expect(preview.previewAspectRatio, closeTo(4 / 3, 0.0001));
      expect(preview.statusLabel, 'Esperando mano');
      expect(preview.cameraSummary, 'Esperando primer preview procesado.');
    });
  });

  group('ProcessedPreviewPanel', () {
    testWidgets('shows fallback copy when preview is unavailable', (
      WidgetTester tester,
    ) async {
      final viewModel = ProcessedPreviewViewModel(
        handDetected: false,
        cameraSummary: 'Esperando primer preview procesado.',
        previewAspectRatio: 4 / 3,
        previewCacheWidth: null,
        previewFrameId: null,
        hasCameraPreview: false,
        previewBytes: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProcessedPreviewPanel(viewModel: viewModel),
            ),
          ),
        ),
      );

      expect(find.text('Preview remoto en espera'), findsOneWidget);
      expect(
        find.text('El backend aun no envio la primera imagen procesada.'),
        findsOneWidget,
      );
    });
  });
}

AutoState _buildState({
  required bool handDetected,
  required String handState,
  required int fingersUp,
  required bool carMoving,
  double carX = 320,
  int speed = 12,
  Uint8List? previewBytes,
  int? previewWidth,
  int? previewHeight,
}) {
  return AutoState(
    timestamp: DateTime(2026, 6, 1, 12, 0),
    handDetected: handDetected,
    handState: handState,
    fingersUp: fingersUp,
    carMoving: carMoving,
    carX: carX,
    carY: 350,
    speed: speed,
    backendReady: true,
    backendMessage: 'Backend listo',
    backendLastError: '',
    previewBytes: previewBytes,
    cameraFrameWidth: previewWidth,
    cameraFrameHeight: previewHeight,
  );
}

HomePresentationInput _buildInput({
  AutoState? state,
  SocketConnectionStatus connectionStatus = SocketConnectionStatus.connected,
  MobileCameraRelayStatus mobileCameraStatus =
      MobileCameraRelayStatus.streaming,
  String statusLabel = 'Conectado',
  String connectionIntro = 'Conexion lista.',
  bool isMobileClient = true,
  String phoneCameraStatusLabel = 'Camara del celular transmitiendo',
  String backendStatusLabel = 'Backend iniciado por Flutter',
  String endpointLabel = 'http://192.168.0.5:5000',
  String connectionHint = 'Usa la IP LAN de tu PC.',
  String backendActionHint = 'Puedes iniciar el backend manualmente.',
  bool isConnecting = false,
  bool isConnected = true,
  bool canRestartManagedBackend = true,
  String backendCommand = r'.\venv\Scripts\python.exe backend\backend.py',
  String backendRecentLog = 'Backend arriba',
  String backendInfoMessage = '',
  String statePreview = '{"hand_detected": true}',
  String handSummary = 'MANO ABIERTA',
  String cameraSummary = 'Vista en vivo recibida desde Flask/OpenCV.',
  String mobileCameraInfoMessage = '',
  String packetLabel = '12:00:00',
  String movementLabel = 'Auto avanzando',
  String errorMessage = '',
}) {
  return HomePresentationInput(
    state:
        state ??
        _buildState(
          handDetected: true,
          handState: 'MANO ABIERTA',
          fingersUp: 5,
          carMoving: true,
          previewBytes: Uint8List.fromList(<int>[1, 2, 3]),
          previewWidth: 900,
          previewHeight: 600,
        ),
    connectionStatus: connectionStatus,
    mobileCameraStatus: mobileCameraStatus,
    statusLabel: statusLabel,
    connectionIntro: connectionIntro,
    isMobileClient: isMobileClient,
    phoneCameraStatusLabel: phoneCameraStatusLabel,
    backendStatusLabel: backendStatusLabel,
    endpointLabel: endpointLabel,
    connectionHint: connectionHint,
    backendActionHint: backendActionHint,
    isConnecting: isConnecting,
    isConnected: isConnected,
    canRestartManagedBackend: canRestartManagedBackend,
    backendCommand: backendCommand,
    backendRecentLog: backendRecentLog,
    backendInfoMessage: backendInfoMessage,
    statePreview: statePreview,
    handSummary: handSummary,
    cameraSummary: cameraSummary,
    mobileCameraInfoMessage: mobileCameraInfoMessage,
    packetLabel: packetLabel,
    movementLabel: movementLabel,
    errorMessage: errorMessage,
  );
}
