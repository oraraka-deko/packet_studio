import 'dart:io';
import 'package:flutter/services.dart';

/// Utility class for accessing native Android features
/// 
/// This class provides methods to interact with the Android native layer,
/// particularly for accessing the native library directory where JNI libraries
/// are installed.
class NativeUtils {
  static const MethodChannel _channel = MethodChannel('studio_packet/native_process');

  /// Get the native library directory path on Android
  /// 
  /// Returns the path where Android installs native libraries (from jniLibs).
  /// This directory has executable permissions, making it suitable for
  /// running binaries that need to be executed.
  /// 
  /// On Android, this typically returns something like:
  /// `/data/app/<package>-<random>/lib/arm64`
  /// 
  /// Throws a [PlatformException] if the native call fails.
  /// Returns empty string on non-Android platforms.
  static Future<String> getLibPath() async {
    if (!Platform.isAndroid) {
      return '';
    }
    
    try {
      final String path = await _channel.invokeMethod<String>('lib_path') ?? '';
      return path;
    } on PlatformException catch (e) {
      throw Exception('Failed to get native library path: ${e.message}');
    }
  }

  /// Get the path to the Dart binary installed as a JNI library
  /// 
  /// Returns the full path to `libdart.so` in the native library directory.
  /// This file must be placed in `android/app/src/main/jniLibs/<abi>/libdart.so`
  /// during the build process.
  /// 
  /// Example return value:
  /// `/data/app/com.example.studio_packet-xxx/lib/arm64/libdart.so`
  /// 
  /// Returns null if not on Android or if the library path cannot be determined.
  static Future<String?> getDartBinaryPath() async {
    if (!Platform.isAndroid) {
      return null;
    }
    
    try {
      final libDir = await getLibPath();
      if (libDir.isEmpty) {
        return null;
      }
      
      final dartPath = '$libDir/libdart.so';
      
      // Verify the file exists
      final file = File(dartPath);
      if (await file.exists()) {
        return dartPath;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if the Dart JNI library is available
  /// 
  /// Returns true if `libdart.so` exists in the native library directory.
  static Future<bool> isDartJniLibAvailable() async {
    final dartPath = await getDartBinaryPath();
    return dartPath != null;
  }
}
