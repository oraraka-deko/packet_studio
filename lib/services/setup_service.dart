import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studio_packet/utils/utils.dart';
import 'package:path/path.dart' as p;

class SetupService {
  static const String _isFirstRunKey = 'isFirstRun';
  static const String _sandboxPathKey = 'sandboxPath';
  static const String _dartSdkPathKey = 'dartSdkPath';
  static const String _workspacePathKey = 'workspacePath';
  static const MethodChannel _nativeProcessChannel = MethodChannel('studio_packet/native_process');

  Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstRunKey) ?? true;
  }

  Future<void> runInitialSetup(void Function(String) onProgress) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await isFirstRun()) return;

    onProgress('Creating sandbox...');
    final sandboxPath = await _createSandbox();
    await prefs.setString(_sandboxPathKey, sandboxPath);

    onProgress('Extracting Dart SDK...');
    final dartSdkPath = await _extractDartSdk(sandboxPath);
    await prefs.setString(_dartSdkPathKey, dartSdkPath);

    onProgress('Creating initial workspace...');
    final workspacePath = await _createWorkspace(dartSdkPath);
    await prefs.setString(_workspacePathKey, workspacePath);

    await prefs.setBool(_isFirstRunKey, false);
    onProgress('Setup complete!');
  }

  Future<String> _createSandbox() async {
    final sandboxesPath = await getSandboxesPath();
    final sandboxDir = Directory(sandboxesPath);
    if (!await sandboxDir.exists()) {
      await sandboxDir.create(recursive: true);
    }
    return sandboxesPath;
  }

  Future<String> _extractDartSdk(String sandboxPath) async {
    final assetPath = Platform.isLinux
        ? 'assets/sdk/linux/dart-sdk-linux-64.tar.xz'
        : 'assets/sdk/android/dart-sdk-android-arm64.tar.xz';

    final byteData = await rootBundle.load(assetPath);
    final buffer = byteData.buffer;

    // This is a blocking operation, run it in a compute isolate
    await compute(_extract, {
      'buffer': buffer.asUint8List(),
      'path': sandboxPath,
    });

    return '$sandboxPath/dart-sdk';
  }

  static void _extract(Map<String, dynamic> args) {
    final buffer = args['buffer'] as Uint8List;
    final path = args['path'] as String;
    final xzDecoder = XZDecoder();
    final tarDecoder = TarDecoder();
    final archive = tarDecoder.decodeBytes(xzDecoder.decodeBytes(buffer));

    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        File('$path/$filename')
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory('$path/$filename').createSync(recursive: true);
      }
    }
  }

  Future<String> _createWorkspace(String dartSdkPath) async {
    const projectName = 'hello_world';
    final prefs = await SharedPreferences.getInstance();
    final sandboxPath = prefs.getString(_sandboxPathKey);

    if (sandboxPath == null || sandboxPath.isEmpty) {
      throw Exception('Sandbox path is not initialized.');
    }

    final dartExecutable = p.join(dartSdkPath, 'bin', 'dart');
    await _ensureExecutablePermission(dartExecutable);

    final result = await _runProcess(
      dartExecutable,
      ['create', projectName],
      workingDirectory: sandboxPath,
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to create workspace: ${result.stderr.isNotEmpty ? result.stderr : result.stdout}');
    }

    return p.join(sandboxPath, projectName);
  }

  Future<_ProcessExecutionResult> _runProcess(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    if (Platform.isAndroid) {
      final response = await _nativeProcessChannel.invokeMapMethod<String, dynamic>(
        'runProcess',
        {
          'executable': executable,
          'arguments': arguments,
          'workingDirectory': workingDirectory,
        },
      );

      if (response == null) {
        throw Exception('Native process runner returned no result.');
      }

      return _ProcessExecutionResult(
        exitCode: response['exitCode'] as int? ?? -1,
        stdout: response['stdout'] as String? ?? '',
        stderr: response['stderr'] as String? ?? '',
      );
    }

    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    );

    return _ProcessExecutionResult(
      exitCode: result.exitCode,
      stdout: (result.stdout ?? '').toString(),
      stderr: (result.stderr ?? '').toString(),
    );
  }

  Future<void> _ensureExecutablePermission(String executablePath) async {
    if (Platform.isWindows || Platform.isAndroid) {
      // Windows does not use executable bits and Android will handle permissions natively.
      return;
    }

    final executable = File(executablePath);
    if (!await executable.exists()) {
      throw Exception('Executable not found at $executablePath');
    }

    final stat = await executable.stat();
    if (stat.modeString().contains('x')) {
      return;
    }

    final chmodResult = await Process.run('chmod', ['+x', executablePath]);
    if (chmodResult.exitCode != 0 && kDebugMode) {
      debugPrint('Unable to mark $executablePath as executable: ${chmodResult.stderr}');
    }
  }
}

class _ProcessExecutionResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  const _ProcessExecutionResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });
}
