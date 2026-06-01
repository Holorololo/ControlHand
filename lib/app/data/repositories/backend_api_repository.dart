import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../dtos/backend_health_dto.dart';
import '../dtos/backend_snapshot_dto.dart';

class BackendApiRepository {
  const BackendApiRepository({
    required http.Client client,
    required String baseUrl,
  }) : _client = client,
       _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<BackendHealthDto> getHealth() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/health'))
        .timeout(const Duration(seconds: 4));

    if (response.statusCode != 200) {
      throw Exception('Estado HTTP ${response.statusCode}');
    }

    return BackendHealthDto.fromJson(_decodeJsonMap(response.body));
  }

  Future<BackendSnapshotDto> getState() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/state'))
        .timeout(const Duration(seconds: 4));

    if (response.statusCode != 200) {
      throw Exception('Estado HTTP ${response.statusCode}');
    }

    return BackendSnapshotDto.fromJson(_decodeJsonMap(response.body));
  }

  Future<Uint8List?> getPreview({int? version}) async {
    final previewUri = Uri.parse(
      '$_baseUrl/camera.jpg?v=${version ?? DateTime.now().millisecondsSinceEpoch}',
    );

    final response = await _client
        .get(previewUri)
        .timeout(const Duration(seconds: 4));

    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      return null;
    }

    return Uint8List.fromList(response.bodyBytes);
  }

  Future<Map<String, dynamic>> sendFrame(Uint8List frameBytes) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/frame'),
          headers: const <String, String>{'Content-Type': 'image/jpeg'},
          body: frameBytes,
        )
        .timeout(const Duration(seconds: 4));

    final payload = response.body;
    final decoded = payload.isEmpty
        ? const <String, dynamic>{}
        : _decodeJsonMap(payload);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          decoded['message']?.toString() ??
          'Respuesta HTTP ${response.statusCode} al subir frame.';
      throw Exception(message);
    }

    return decoded;
  }

  Map<String, dynamic> _decodeJsonMap(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El backend envio un JSON inesperado.');
    }

    return decoded;
  }
}
