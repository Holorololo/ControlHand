import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

enum BackendRuntimeStatus {
  idle,
  locating,
  starting,
  running,
  external,
  unavailable,
  failed,
}

class BackendProcessService extends GetxService {
  final Rx<BackendRuntimeStatus> status = BackendRuntimeStatus.idle.obs;
  final RxString infoMessage = ''.obs;
  final RxString recentLog = ''.obs;

  Process? _process;
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;
  bool _ownsProcess = false;
  bool _startInProgress = false;
  int? _lastExitCode;

  bool get canAutoStart =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  bool canManageHost(String host) {
    final normalizedHost = _normalizeHost(host);
    return canAutoStart && _isLoopbackHost(normalizedHost);
  }

  Future<void> ensureStarted({
    String host = '127.0.0.1',
    int port = 5000,
  }) async {
    final normalizedHost = _normalizeHost(host);

    if (!_isLoopbackHost(normalizedHost)) {
      status.value = BackendRuntimeStatus.external;
      infoMessage.value =
          'Host remoto configurado en http://$normalizedHost:$port. Flutter no iniciara Python local; levanta el backend en ese equipo.';
      return;
    }

    if (!canAutoStart) {
      status.value = BackendRuntimeStatus.unavailable;
      infoMessage.value =
          'En movil no se puede iniciar este Python local desde la app. Usa adb reverse o conecta al backend Flask por red.';
      return;
    }

    if (_startInProgress) {
      return;
    }

    if (await _isBackendHealthy(normalizedHost, port)) {
      status.value = BackendRuntimeStatus.external;
      infoMessage.value =
          'Se detecto un backend Flask ya activo en http://$normalizedHost:$port.';
      return;
    }

    if (_process != null && !_hasExited(_process!)) {
      status.value = BackendRuntimeStatus.starting;
      final connected = await _waitForBackend(port);
      status.value = connected
          ? BackendRuntimeStatus.running
          : BackendRuntimeStatus.failed;
      if (connected) {
        infoMessage.value =
            'Backend Flask iniciado por Flutter y ya disponible.';
      } else {
        infoMessage.value =
            'Flutter esperaba al backend Flask, pero no respondio /health.';
      }
      return;
    }

    _startInProgress = true;
    status.value = BackendRuntimeStatus.locating;
    infoMessage.value = 'Buscando Python y backend dentro del proyecto...';

    try {
      final launchConfig = _resolveLaunchConfig();
      if (launchConfig == null) {
        status.value = BackendRuntimeStatus.unavailable;
        infoMessage.value =
            'No se encontro un entorno Python valido ni el script backend.';
        return;
      }

      status.value = BackendRuntimeStatus.starting;
      infoMessage.value = 'Iniciando backend Flask desde Flutter...';

      final process = await Process.start(
        launchConfig.pythonExecutable.path,
        <String>[
          launchConfig.scriptFile.path,
          '--mode',
          'backend',
          '--host',
          '0.0.0.0',
          '--port',
          '$port',
        ],
        workingDirectory: launchConfig.projectRoot.path,
        runInShell: false,
      );

      _process = process;
      _ownsProcess = true;
      _lastExitCode = null;
      _listenToProcess(process);

      final connected = await _waitForBackend(port);
      status.value = connected
          ? BackendRuntimeStatus.running
          : BackendRuntimeStatus.failed;
      infoMessage.value = connected
          ? 'Backend Flask iniciado automaticamente.'
          : 'Flutter inicio Python, pero Flask no respondio en /health.';
    } catch (error) {
      status.value = BackendRuntimeStatus.failed;
      infoMessage.value = 'No se pudo iniciar el backend Flask.';
      recentLog.value = error.toString();
    } finally {
      _startInProgress = false;
    }
  }

  Future<void> stopManagedBackend() async {
    if (_process == null || !_ownsProcess) {
      return;
    }

    status.value = BackendRuntimeStatus.idle;
    infoMessage.value = 'Backend Flask detenido desde Flutter.';
    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();
    _stdoutSubscription = null;
    _stderrSubscription = null;

    _process!.kill();
    _process = null;
    _ownsProcess = false;
    _lastExitCode = null;
  }

  void _listenToProcess(Process process) {
    process.exitCode.then((exitCode) {
      _lastExitCode = exitCode;
      if (exitCode != 0) {
        recentLog.value = 'El backend termino con codigo $exitCode.';
        if (status.value == BackendRuntimeStatus.starting ||
            status.value == BackendRuntimeStatus.running) {
          status.value = BackendRuntimeStatus.failed;
          infoMessage.value = 'El backend Flask se cerro inesperadamente.';
        }
      }
    });

    _stdoutSubscription = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleProcessLine);

    _stderrSubscription = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleProcessLine);
  }

  void _handleProcessLine(String line) {
    recentLog.value = line;

    if (line.contains('Backend Flask escuchando')) {
      status.value = BackendRuntimeStatus.running;
      infoMessage.value = line;
    }
  }

  Future<bool> _waitForBackend(
    int port, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      if (await _isBackendHealthy('127.0.0.1', port)) {
        return true;
      }

      if (_process != null && _hasExited(_process!)) {
        return false;
      }

      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    return false;
  }

  Future<bool> _isBackendHealthy(String host, int port) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse('http://$host:$port/health'),
      );
      final response = await request.close().timeout(
        const Duration(milliseconds: 1200),
      );
      await response.drain<void>();
      return response.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  _BackendLaunchConfig? _resolveLaunchConfig() {
    for (final startDirectory in _candidateStartDirectories()) {
      final projectRoot = _findProjectRoot(startDirectory);
      if (projectRoot == null) {
        continue;
      }

      final scriptFile = File(
        _join(projectRoot.path, <String>['backend', 'backend.py']),
      );

      if (!scriptFile.existsSync()) {
        continue;
      }

      final pythonCandidates = <File>[
        File(
          _join(projectRoot.path, <String>['venv', 'Scripts', 'python.exe']),
        ),
        File(
          _join(projectRoot.path, <String>['.venv', 'Scripts', 'python.exe']),
        ),
        File(_join(projectRoot.path, <String>['venv', 'bin', 'python'])),
        File(_join(projectRoot.path, <String>['.venv', 'bin', 'python'])),
      ];

      for (final pythonExecutable in pythonCandidates) {
        if (pythonExecutable.existsSync()) {
          return _BackendLaunchConfig(
            projectRoot: projectRoot,
            pythonExecutable: pythonExecutable,
            scriptFile: scriptFile,
          );
        }
      }
    }

    return null;
  }

  Iterable<Directory> _candidateStartDirectories() sync* {
    yield Directory.current;
    yield File(Platform.resolvedExecutable).parent;
  }

  Directory? _findProjectRoot(Directory startDirectory) {
    Directory? current = startDirectory.absolute;

    while (current != null) {
      final pubspec = File(_join(current.path, <String>['pubspec.yaml']));
      final backendScript = File(
        _join(current.path, <String>['backend', 'backend.py']),
      );

      if (pubspec.existsSync() && backendScript.existsSync()) {
        return current;
      }

      final parent = current.parent;
      if (parent.path == current.path) {
        break;
      }
      current = parent;
    }

    return null;
  }

  String _join(String base, List<String> segments) {
    return <String>[base, ...segments].join(Platform.pathSeparator);
  }

  String _normalizeHost(String host) {
    var normalizedHost = host.trim();

    if (normalizedHost.contains('://')) {
      final uri = Uri.tryParse(normalizedHost);
      if (uri != null && uri.host.isNotEmpty) {
        normalizedHost = uri.host;
      }
    }

    return normalizedHost
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceAll('/', '');
  }

  bool _isLoopbackHost(String host) {
    final normalizedHost = host.trim().toLowerCase();
    return normalizedHost == '127.0.0.1' ||
        normalizedHost == 'localhost' ||
        normalizedHost == '::1' ||
        normalizedHost == '[::1]';
  }

  bool _hasExited(Process process) {
    return identical(process, _process) && _lastExitCode != null;
  }

  @override
  void onClose() {
    _stdoutSubscription?.cancel();
    _stderrSubscription?.cancel();
    if (_process != null && _ownsProcess) {
      _process!.kill();
    }
    super.onClose();
  }
}

class _BackendLaunchConfig {
  const _BackendLaunchConfig({
    required this.projectRoot,
    required this.pythonExecutable,
    required this.scriptFile,
  });

  final Directory projectRoot;
  final File pythonExecutable;
  final File scriptFile;
}
