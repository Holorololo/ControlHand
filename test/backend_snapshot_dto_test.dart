import 'package:flutter_test/flutter_test.dart';

import 'package:movilcontrol/app/data/dtos/backend_snapshot_dto.dart';
import 'package:movilcontrol/app/data/models/auto_state.dart';

void main() {
  group('BackendSnapshotDto', () {
    test('parses backend hand and command fields correctly', () {
      final dto = BackendSnapshotDto.fromJson(<String, dynamic>{
        'timestamp': 1.0,
        'hand_detected': true,
        'hand_status': 'closed',
        'hand_state': 'MANO CERRADA',
        'finger_count': 0,
        'command': 'forward',
        'payload': 'F',
        'car_moving': true,
        'car_x': 120,
        'car_y': 350,
        'speed': 8,
        'backend_ready': true,
        'backend_source': 'mobile',
        'backend_message': 'Backend listo',
        'backend_last_error': '',
        'camera_preview_available': false,
        'camera_preview_width': 480,
        'camera_preview_height': 320,
        'camera_preview_version': 3,
      });

      expect(dto.handDetected, isTrue);
      expect(dto.handStatus, 'closed');
      expect(dto.handState, 'MANO CERRADA');
      expect(dto.fingerCount, 0);
      expect(dto.command, 'forward');
      expect(dto.payload, 'F');
    });

    test('distinguishes no hand from closed hand with zero fingers', () {
      final noHand = AutoState.fromJson(<String, dynamic>{
        'timestamp': 1.0,
        'hand_detected': false,
        'hand_status': 'none',
        'finger_count': 0,
        'command': 'stop',
        'payload': 'S',
        'car_moving': false,
        'car_x': 50,
        'car_y': 350,
        'speed': 8,
        'backend_ready': true,
        'backend_source': 'mobile',
        'backend_message': 'Sin mano',
        'backend_last_error': '',
        'camera_preview_available': false,
      });
      final closedHand = AutoState.fromJson(<String, dynamic>{
        'timestamp': 2.0,
        'hand_detected': true,
        'hand_status': 'closed',
        'finger_count': 0,
        'command': 'forward',
        'payload': 'F',
        'car_moving': true,
        'car_x': 60,
        'car_y': 350,
        'speed': 8,
        'backend_ready': true,
        'backend_source': 'mobile',
        'backend_message': 'Mano cerrada',
        'backend_last_error': '',
        'camera_preview_available': false,
      });

      expect(noHand.handDetected, isFalse);
      expect(noHand.payload, 'S');
      expect(closedHand.handDetected, isTrue);
      expect(closedHand.payload, 'F');
      expect(noHand.payload, isNot(closedHand.payload));
    });
  });
}
