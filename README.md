# studio_packet

A new Flutter project.

## Android Dart SDK Integration

This project uses a special workaround to run the Dart SDK on Android by packaging the Dart binary as a JNI library.

### Why This Approach?

Android restricts execution of binaries extracted from app data directories due to:
- `noexec` mount flags on `/data/data` partitions
- SELinux policies
- Security restrictions

The workaround is to place executables in `jniLibs` so Android's package installer:
- Copies them to the native library directory with executable permissions
- Bypasses the restrictions that affect extracted files

This pattern is also used by projects like [`nightmare-space/code_lfa`](https://github.com/nightmare-space/code_lfa) for running `bash`, `busybox`, and `proot`.

### How to Add the Dart Binary

1. **Build or obtain the Dart SDK for Android ARM64**:
   - Cross-compile Dart SDK for Android ARM64, or
   - Download from official Dart SDK releases

2. **Rename and place the binary**:
   ```bash
   # Rename the dart binary to libdart.so
   cp /path/to/dart-sdk/bin/dart android/app/src/main/jniLibs/arm64-v8a/libdart.so
   ```

3. **The binary will be automatically**:
   - Packaged into the APK during build
   - Installed to `/data/app/<package>/lib/arm64/libdart.so`
   - Given executable permissions by Android

4. **The app automatically uses it**:
   - `SetupService` checks for `libdart.so` in the native library directory
   - If found, it uses it instead of the extracted SDK binary
   - If not found, it falls back to extracting from assets
   - As a last resort on rooted devices, it can use root access to set permissions

### Multi-ABI Support

To support multiple architectures:

```
android/app/src/main/jniLibs/
├── arm64-v8a/
│   └── libdart.so      # 64-bit ARM (most modern devices)
├── armeabi-v7a/
│   └── libdart.so      # 32-bit ARM (older devices)
└── x86_64/
    └── libdart.so      # 64-bit x86 (emulators)
```

Each `libdart.so` must be the architecture-specific binary renamed.

### Technical Details

**Android Side** (`MainActivity.kt`):
- Exposes `lib_path` method via MethodChannel
- Returns `applicationInfo.nativeLibraryDir`

**Dart Side** (`lib/utils/native_utils.dart`):
- `NativeUtils.getLibPath()` - Gets native library directory
- `NativeUtils.getDartBinaryPath()` - Returns full path to `libdart.so`
- `NativeUtils.isDartJniLibAvailable()` - Checks if binary exists

**Integration** (`lib/services/setup_service.dart`):
- `getDartExecutablePath()` - Returns JNI path or falls back to extracted SDK
- `_createWorkspace()` - Automatically uses JNI binary when available
- `_ensureExecutablePermission()` - Tries chmod, then root access as last fallback
- Uses `root_plus` package on rooted devices when other methods fail

### Execution Permission Fallback Chain

The app tries multiple methods to ensure the Dart binary is executable:

1. **JNI Library** (Preferred): Uses `libdart.so` from `jniLibs` - no permission issues
2. **Normal chmod**: Attempts standard `chmod +x` on extracted SDK binary
3. **Root Access** (Last Resort): On rooted devices, uses `root_plus` to set permissions

This layered approach ensures maximum compatibility across different Android devices and configurations.

### References

- [nightmare-space/code_lfa](https://github.com/nightmare-space/code_lfa) - Similar approach for bash/proot
- See `android/app/src/main/jniLibs/README.md` for more details
