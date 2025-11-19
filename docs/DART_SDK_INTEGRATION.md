# Dart SDK Integration Guide

## Overview

This guide explains how to integrate a compiled Dart SDK binary with your Android app using the JNI library approach.

## Quick Start

1. **Get the Dart SDK binary for Android ARM64**
   ```bash
   # If you have compiled it yourself
   cd /home/ns/Documents/ws/dart-sdk/sdk/out/ReleaseAndroidARM64/dart-sdk/bin
   
   # Copy it to your project
   cp dart /path/to/packet_studio/android/app/src/main/jniLibs/arm64-v8a/libdart.so
   ```

2. **Build and run your app**
   ```bash
   flutter build apk
   # or
   flutter run
   ```

3. **The app will automatically**:
   - Package `libdart.so` into the APK
   - Android will install it with executable permissions
   - Your app will use it instead of the extracted SDK

## Verification

You can verify the integration is working by checking the debug logs:

```
Using Dart binary from JNI library: /data/app/com.example.studio_packet-.../lib/arm64/libdart.so
```

If the JNI library is not found, you'll see:

```
JNI library not found, using extracted SDK: /data/data/.../dart-sdk/bin/dart
```

## Code Usage

### Get Dart executable path

```dart
import 'package:studio_packet/services/setup_service.dart';

final setupService = SetupService();
final dartPath = await setupService.getDartExecutablePath();
print('Dart executable: $dartPath');
```

### Check if JNI library is available

```dart
import 'package:studio_packet/utils/native_utils.dart';

if (await NativeUtils.isDartJniLibAvailable()) {
  print('Using JNI library approach');
  final path = await NativeUtils.getDartBinaryPath();
  print('Path: $path');
} else {
  print('JNI library not available, using fallback');
}
```

### Run Dart processes

```dart
import 'package:studio_packet/services/setup_service.dart';

final setupService = SetupService();
final dartPath = await setupService.getDartExecutablePath();

if (dartPath != null) {
  final result = await setupService.runProcess(
    dartPath,
    ['--version'],
  );
  
  print('Exit code: ${result.exitCode}');
  print('Output: ${result.stdout}');
}
```

## Multi-Architecture Support

To support multiple device types:

### 1. Build for each architecture

```bash
# Build for ARM64 (modern phones)
cd dart-sdk/sdk
python3 tools/build.py -m release -a arm64 create_sdk

# Build for ARM32 (older phones)
python3 tools/build.py -m release -a arm create_sdk

# Build for x86_64 (emulators)
python3 tools/build.py -m release -a x64 create_sdk
```

### 2. Copy to appropriate directories

```bash
# ARM64
cp out/ReleaseAndroidARM64/dart-sdk/bin/dart \
   android/app/src/main/jniLibs/arm64-v8a/libdart.so

# ARM32
cp out/ReleaseAndroidARM/dart-sdk/bin/dart \
   android/app/src/main/jniLibs/armeabi-v7a/libdart.so

# x86_64
cp out/ReleaseAndroidX64/dart-sdk/bin/dart \
   android/app/src/main/jniLibs/x86_64/libdart.so
```

### 3. Update build.gradle.kts

If you only want specific ABIs:

```kotlin
android {
    defaultConfig {
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
    }
}
```

## Troubleshooting

### Binary not found

**Problem**: App doesn't detect `libdart.so`

**Solution**: 
1. Verify file exists: `ls android/app/src/main/jniLibs/arm64-v8a/libdart.so`
2. Check it's actually a binary: `file android/app/src/main/jniLibs/arm64-v8a/libdart.so`
3. Rebuild: `flutter clean && flutter build apk`

### Wrong architecture

**Problem**: App crashes with "cannot execute binary file"

**Solution**: 
- Make sure you're using the correct architecture binary
- Check device ABI: `adb shell getprop ro.product.cpu.abi`
- Use the matching binary for that ABI

### Permission denied

**Problem**: Still getting permission errors

**Solution**: 
- The app now has a multi-layered fallback system:
  1. First tries JNI library (no permission issues)
  2. Then tries standard `chmod +x`
  3. Finally, on rooted devices, uses `root_plus` package for root access
- Check debug logs to see which method was attempted
- If device is rooted and you see "Device is rooted, attempting to use root access", grant root permission when prompted
- Make sure you're testing on actual Android, not Linux

### Root Access Fallback

**When it's used**: 
- Only as a last resort when JNI library is not available and normal chmod fails
- Only on Android devices that are rooted
- Automatically detected and attempted

**How it works**:
1. App checks if device has root access using `root_plus` package
2. If rooted, requests root permission (user prompt may appear)
3. Executes `chmod +x` with root privileges
4. Logs result in debug mode

**Note**: Root access is completely optional and only used as a fallback for maximum compatibility.

## Advanced: Build Script

You can automate the process with a script:

```bash
#!/bin/bash
# scripts/copy-dart-sdk.sh

DART_SDK_PATH="/home/ns/Documents/ws/dart-sdk/sdk/out/ReleaseAndroidARM64/dart-sdk/bin"
PROJECT_PATH="$(dirname "$0")/.."

if [ ! -f "$DART_SDK_PATH/dart" ]; then
    echo "Error: Dart binary not found at $DART_SDK_PATH"
    exit 1
fi

mkdir -p "$PROJECT_PATH/android/app/src/main/jniLibs/arm64-v8a"
cp "$DART_SDK_PATH/dart" "$PROJECT_PATH/android/app/src/main/jniLibs/arm64-v8a/libdart.so"

echo "Copied Dart SDK binary to jniLibs"
echo "You can now build the app with: flutter build apk"
```

Make it executable and run:

```bash
chmod +x scripts/copy-dart-sdk.sh
./scripts/copy-dart-sdk.sh
```

## References

- [nightmare-space/code_lfa](https://github.com/nightmare-space/code_lfa) - Reference implementation
- [Android NDK Documentation](https://developer.android.com/ndk/guides/abis)
- [Dart SDK Build Instructions](https://github.com/dart-lang/sdk/wiki/Building)
