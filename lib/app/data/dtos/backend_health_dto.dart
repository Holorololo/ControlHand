class BackendHealthDto {
  const BackendHealthDto({
    required this.ok,
    required this.backendReady,
    required this.backendSource,
    required this.backendMessage,
    required this.backendLastError,
    required this.cameraPreviewAvailable,
    required this.cameraPreviewVersion,
    required this.timestamp,
  });

  factory BackendHealthDto.fromJson(Map<String, dynamic> json) {
    final timestampSeconds = (json['timestamp'] as num?)?.toDouble() ?? 0;
    final milliseconds = (timestampSeconds * 1000).round();

    return BackendHealthDto(
      ok: json['ok'] == true,
      backendReady: json['backend_ready'] == true,
      backendSource: (json['backend_source'] as String?) ?? '',
      backendMessage: (json['backend_message'] as String?) ?? '',
      backendLastError: (json['backend_last_error'] as String?) ?? '',
      cameraPreviewAvailable: json['camera_preview_available'] == true,
      cameraPreviewVersion: (json['camera_preview_version'] as num?)?.toInt(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
        isUtc: true,
      ).toLocal(),
    );
  }

  final bool ok;
  final bool backendReady;
  final String backendSource;
  final String backendMessage;
  final String backendLastError;
  final bool cameraPreviewAvailable;
  final int? cameraPreviewVersion;
  final DateTime timestamp;
}
