import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:movilcontrol/app/data/dtos/backend_health_dto.dart';
import 'package:movilcontrol/app/data/dtos/backend_snapshot_dto.dart';
import 'package:movilcontrol/app/data/enums/hand_gesture_type.dart';
import 'package:movilcontrol/app/data/enums/vehicle_motion_state.dart';
import 'package:movilcontrol/app/data/repositories/backend_api_repository.dart';
import 'package:movilcontrol/app/services/auto_state_polling_service.dart';

void main() {
  group('AutoStatePollingService', () {
    test('preview failure does not block latest state publication', () async {
      final repository = _FakeBackendApiRepository(
        snapshot: _buildSnapshot(previewAvailable: true, previewVersion: 7),
        previewError: TimeoutException('preview timeout'),
      );
      final service = AutoStatePollingService(
        clientFactory: http.Client.new,
        repositoryFactory: (client, baseUrl) => repository,
      );

      await service.connect(host: '127.0.0.1', port: 5000);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(service.status.value, SocketConnectionStatus.connected);
      expect(service.errorMessage.value, isEmpty);
      expect(service.latestState.value, isNotNull);
      expect(service.latestState.value!.handState, 'MANO ABIERTA');
      expect(service.latestState.value!.carMoving, isTrue);
      expect(service.lastPreviewError, contains('preview timeout'));

      await service.disconnect();
      service.onClose();
    });

    test(
      'slow preview refresh does not delay connect or state publish',
      () async {
        final repository = _FakeBackendApiRepository(
          snapshot: _buildSnapshot(previewAvailable: true, previewVersion: 9),
          previewDelay: const Duration(milliseconds: 180),
          previewBytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
        );
        final service = AutoStatePollingService(
          clientFactory: http.Client.new,
          repositoryFactory: (client, baseUrl) => repository,
        );

        final stopwatch = Stopwatch()..start();
        await service.connect(host: '127.0.0.1', port: 5000);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(120));
        expect(service.latestState.value, isNotNull);
        expect(service.latestState.value!.handState, 'MANO ABIERTA');

        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect(service.previewFetchInProgress, isTrue);

        await Future<void>.delayed(const Duration(milliseconds: 220));
        expect(service.latestState.value!.hasCameraPreview, isTrue);
        expect(service.lastPreviewFetchMs, greaterThan(0));

        await service.disconnect();
        service.onClose();
      },
    );
  });
}

class _FakeBackendApiRepository extends BackendApiRepository {
  _FakeBackendApiRepository({
    required this.snapshot,
    this.previewBytes,
    this.previewDelay = Duration.zero,
    this.previewError,
  }) : super(client: http.Client(), baseUrl: 'http://fake-backend');

  final BackendSnapshotDto snapshot;
  final Uint8List? previewBytes;
  final Duration previewDelay;
  final Object? previewError;

  @override
  Future<BackendHealthDto> getHealth() async {
    return BackendHealthDto(
      ok: true,
      backendReady: true,
      backendSource: 'mobile',
      backendMessage: 'Backend listo',
      backendLastError: '',
      cameraPreviewAvailable: false,
      cameraPreviewVersion: null,
      timestamp: DateTime(2026, 6, 5, 10, 30),
    );
  }

  @override
  Future<BackendSnapshotDto> getState() async {
    return snapshot;
  }

  @override
  Future<Uint8List?> getPreview({int? version}) async {
    if (previewDelay > Duration.zero) {
      await Future<void>.delayed(previewDelay);
    }

    if (previewError != null) {
      throw previewError!;
    }

    return previewBytes;
  }
}

BackendSnapshotDto _buildSnapshot({
  required bool previewAvailable,
  required int previewVersion,
}) {
  return BackendSnapshotDto(
    timestamp: DateTime(2026, 6, 5, 10, 30),
    handDetected: true,
    handState: 'MANO ABIERTA',
    fingersUp: 5,
    carMoving: true,
    carX: 420,
    carY: 350,
    speed: 14,
    backendReady: true,
    backendSource: 'mobile',
    backendMessage: 'Backend listo',
    backendLastError: '',
    cameraPreviewAvailable: previewAvailable,
    cameraPreviewWidth: 640,
    cameraPreviewHeight: 480,
    cameraPreviewVersion: previewVersion,
    handGestureType: HandGestureType.open,
    vehicleMotionState: VehicleMotionState.moving,
  );
}
