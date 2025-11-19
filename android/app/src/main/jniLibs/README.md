# JNI Libraries Directory

This directory contains native libraries that will be packaged into the APK and installed with executable permissions.

## Dart SDK Binary

To use the Dart SDK on Android, place the compiled Dart binary here renamed as `libdart.so`:

### For arm64-v8a (64-bit ARM):
```
android/app/src/main/jniLibs/arm64-v8a/libdart.so
```

### How to prepare the binary:

1. Build or obtain the Dart SDK for Android ARM64:
   - Cross-compile Dart SDK for Android ARM64
   - Or download from official Dart SDK releases

2. Rename the `dart` binary to `libdart.so`:
   ```bash
   cp /path/to/dart-sdk/bin/dart arm64-v8a/libdart.so
   ```

3. The binary will be automatically packaged into the APK and installed to:
   `/data/app/<package>-<random>/lib/arm64/libdart.so`

4. Android will give it executable permissions automatically.

## Multi-ABI Support

To support multiple architectures, create additional directories:

- `armeabi-v7a/libdart.so` - 32-bit ARM
- `x86_64/libdart.so` - 64-bit x86 (for emulators)

Each directory should contain the corresponding architecture-specific binary renamed to `libdart.so`.

## Why This Approach?

Android restricts execution of binaries from regular app data directories due to:
- `noexec` mount flags
- SELinux policies
- Security restrictions

By placing executables in `jniLibs`, Android's package installer:
- Copies them to the native library directory
- Grants executable permissions automatically
- Bypasses the restrictions that affect extracted files

This is the same pattern used by projects like `nightmare-space/code_lfa` for `bash`, `busybox`, and `proot`.
