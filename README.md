# device_trust

[![pub package](https://img.shields.io/pub/v/device_trust.svg)](https://pub.dev/packages/device_trust)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/MuhammedErdemKazanci/device_trust/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/MuhammedErdemKazanci/device_trust/actions/workflows/ci.yml)

## Heuristic Device Integrity Signals for Flutter

Lightweight detection of compromised devices: **root/jailbreak**, **emulator/simulator**, **hook/Frida**, and **debugger** attachment — for both **Android** and **iOS**. No third-party SDKs.

| iOS | Android |
| --- | ------- |
| ![iOS Summary](https://github.com/MuhammedErdemKazanci/device_trust/raw/main/screenshots/ios-summary.png) | ![Android Summary](https://github.com/MuhammedErdemKazanci/device_trust/raw/main/screenshots/android-summary.png) |

---

## Features

- ✅ **Android**: Kotlin + C++ (JNI) for native signal collection
- ✅ **iOS**: Swift + Objective-C++ for native security checks
- ✅ **Heuristic approach**: Multi-signal detection with fail-soft behavior
- ✅ **Fast**: Targets 1–20 ms total execution time (native scans typically 1–5 ms)
- ✅ **Typed API**: `DeviceTrustReport` model via MethodChannel
- ✅ **No third-party dependencies**: Pure platform code, no external SDKs

---

## Supported Platforms

| Platform | Minimum Version | Notes |
| -------- | --------------- | ----- |
| **Android** | API 24+ (Android 7.0) | Kotlin + C++ JNI |
| **iOS** | iOS 13.0+ | Swift 5.0 |

---

## Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  device_trust: ^3.1.0
```

Run:

```bash
flutter pub get
```

### Basic Usage

```dart
import 'package:device_trust/device_trust.dart';

Future<void> checkDeviceTrust() async {
  // Get the device trust report
  final report = await DeviceTrust.getReport();

  // Simple policy: compromised if any major flag is true
  final compromised = report.rootedOrJailbroken ||
      report.fridaSuspected ||
      report.emulator ||
      report.debuggerAttached;

  if (compromised) {
    print('⚠️  Device integrity compromised');
  } else {
    print('✅ Device appears secure');
  }

  // Log detailed signals
  print('Details: ${report.details}');
}
```

### Platform-Specific Checks

```dart
final report = await DeviceTrust.getReport();

// Android-specific
if (report.devModeEnabled) {
  print('Developer mode is enabled');
}
if (report.adbEnabled) {
  print('ADB debugging is enabled');
}

// iOS-specific: check jailbreak paths
final jbPaths = report.details['jbPathHits'] as List<dynamic>? ?? [];
if (jbPaths.isNotEmpty) {
  print('Jailbreak paths detected: $jbPaths');
}
```

---

## API Reference

### `DeviceTrust.getReport()`

Returns a `Future<DeviceTrustReport>` with the following fields:

| Field | Type | Description |
| ----- | ---- | ----------- |
| `rootedOrJailbroken` | `bool` | Device is rooted (Android) or jailbroken (iOS) |
| `emulator` | `bool` | Running on emulator/simulator |
| `fridaSuspected` | `bool` | Frida or hooking framework detected |
| `debuggerAttached` | `bool` | Debugger is attached to the process |
| `devModeEnabled` | `bool` | Developer mode enabled (Android only) |
| `adbEnabled` | `bool` | ADB debugging enabled (Android only) |
| `details` | `Map<String, dynamic>` | Platform-specific signals and metadata |
| `flags` | `int` | Stored compact bit-set backing the six boolean accessors |

Use `hasFlag` with `DeviceTrustFlag` when a bit-set check is more convenient:

```dart
if (report.hasFlag(DeviceTrustFlag.fridaSuspected)) {
  print('Hooking framework suspected');
}

print('Compact flags: ${report.flags}');
```

### `DeviceTrust.isSupported()`

Returns `Future<bool>` indicating whether the current platform is supported.

### Native Transport Format

The public Dart API remains the typed `DeviceTrustReport` described above. Across
the internal platform channel, Android and iOS encode each report as a compact,
versioned payload:

```text
[formatVersion, flags, details]
```

Format version `1` assigns the six report booleans to these bit masks:

| Bit mask | Dart field |
| -------- | ---------- |
| `1` | `rootedOrJailbroken` |
| `2` | `emulator` |
| `4` | `devModeEnabled` |
| `8` | `adbEnabled` |
| `16` | `fridaSuspected` |
| `32` | `debuggerAttached` |

The Dart report stores the received `flags` value as its source of truth and
derives the six named boolean accessors from their masks. Unknown higher bits
remain available through `report.flags` while existing accessors ignore them,
so compatible native implementations can add summary signals without changing
existing ones.

For example, `[1, 17, details]` means format version `1` with
`rootedOrJailbroken` and `fridaSuspected` set (`1 + 16`). The `details` map
continues to contain descriptive, platform-specific diagnostic signals.

---

## Platform Notes

### Android

- **Manifest Queries**: The plugin's `AndroidManifest.xml` declares `<queries>` for common root management apps (Magisk, SuperSU, etc.) and Frida server. These merge automatically via Gradle—no manual configuration needed.
- **Native Library**: C++ code is compiled into an AAR with the following ABIs:
  - `arm64-v8a` (64-bit ARM)
  - `armeabi-v7a` (32-bit ARM)
  - `x86_64` (64-bit x86)
- **Auto-linking**: CMake/ndk-build handles linking; no additional setup required.
- **Gradle/Kotlin Compatibility**: Version 3.0.0+ is migrated for Android's
  built-in Kotlin integration and no longer applies the Kotlin Gradle Plugin.
  No consumer-side Kotlin configuration is required by `device_trust`.
- **16KB Page Size Support**: Android devices with 16KB page size are supported (Android 15+ on some devices). The native library is built with `-Wl,-z,max-page-size=16384` for all ABIs. We recommend using a modern NDK (r26+) for optimal compatibility.

### iOS

#### Dependency Manager Support

`device_trust` supports both **CocoaPods** and **Swift Package Manager** for
iOS native Flutter plugin integration. Flutter application developers add and
use `device_trust` as a normal Dart/pub dependency — no manual native
package configuration is required.

- **Versions 2.x** of this Flutter package require **Flutter 3.41.0 or later**
  and **Dart ^3.11.0** for all consumers, regardless of iOS dependency manager.
- **Version 3.0.0+** requires **Flutter 3.44.0 or later** and **Dart ^3.12.0**
  for Android built-in Kotlin compatibility. Projects on older Flutter releases
  should remain on `device_trust: ^2.0.1`.
- **Swift Package Manager**: Enable Flutter's SPM integration via
  `flutter config --enable-swift-package-manager`, then run your app normally.
  Flutter resolves `device_trust` through its native Swift package target automatically.
- **CocoaPods**: Remains fully supported for iOS native integration. CocoaPods-based
  consumers must also meet the minimum Flutter and Dart SDK requirements as above.

> **Note:** `device_trust` is a Flutter plugin, not a standalone native Swift
> library. The supported consumer API is the Flutter package API exposed
> from Dart.

#### URL Schemes

For jailbreak detection, the plugin checks if certain URL schemes can be opened (`cydia://`, `sileo://`, etc.). Add these to your app's `Info.plist` under `LSApplicationQueriesSchemes`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>cydia</string>
    <string>sileo</string>
    <string>zbra</string>
    <string>filza</string>
    <string>undecimus</string>
    <string>activator</string>
</array>
```

**Note**: This is for `canOpenURL` checks only—no URLs are actually opened.

- **Anti-Debug**: The native function `DTNDenyDebuggerAttach()` calls `ptrace(PT_DENY_ATTACH)`, but **only** in:
  - **Release** builds (not Debug)
  - **Physical devices** (not Simulator)

  In Debug/Simulator, it's a no-op to avoid interfering with development.

- **Bridging Header**: Not required. CocoaPods framework mode exposes C functions via the umbrella header, so Swift code sees them automatically.

---

## Performance & Error Behavior

- **Native Scan Duration**: Typically 1–5 ms for file checks, process inspection, and memory analysis.
- **Total Time**: Targets 1–20 ms end-to-end (native + Dart overhead).
- **Fail-soft signal collection**: Individual native checks isolate recoverable
  failures and record diagnostic information where possible, so one unavailable
  signal does not invalidate the whole report.
- **API errors remain explicit**: The outer `DeviceTrust.getReport()` timeout
  throws `TimeoutException`; missing, malformed, or failed platform-channel
  responses can throw Flutter platform exceptions. Callers should handle these
  errors according to their own risk policy.

---

## Limitations & Security Notes

### Not 100% Detection

This plugin uses **heuristic detection**, which can be bypassed by:

- **Magisk Hide**, **Shamiko** (root cloaking on Android)
- **Frida stealth mode**, **Objection** (hooking framework concealment)
- Custom OS modifications or kernel patches

### Multi-Signal Decision

- The plugin **does not make blocking decisions** for you.
- Use multiple signals together to build a robust policy:
  
  ```dart
  final highRisk = report.rootedOrJailbroken && report.fridaSuspected;
  final mediumRisk = report.emulator || report.debuggerAttached;
  ```

### False Positives

- **Emulators/Simulators** are flagged as compromised by default. In production, you may want to allow them for internal testing.
- **Debug mode** always attaches a debugger—this is expected during development.

### Compact Transport Is Not Tamper Protection

The bit-packed native payload makes the six summary boolean field names less
explicit on the platform channel, but it is only a small defense-in-depth
measure. The diagnostic `details` map remains descriptive, and the encoding is
not encryption, authentication, attestation, or anti-hooking protection. An
attacker who controls the client can still observe or modify the numeric payload,
hook the decoder, or alter the resulting Dart object. Do not use the transport
format as a trust boundary; combine multiple signals with server-side validation
and platform attestation where appropriate.

---

## Example App

The `example/` directory contains a production-level diagnostic UI that displays:

- **Summary** of all flags (color-coded)
- **Policy evaluation** (example)
- **JSON details** (with copy-to-clipboard)
- **Detected signals** (paths, URL schemes, libraries)

Run it:

```bash
cd example
flutter run -d <device-or-simulator>
```

See [`example/README.md`](example/README.md) for platform-specific expectations (e.g., simulator shows `emulator: true`).

---

## FAQ

### Why is there no bridging header for iOS?

Under CocoaPods, framework mode (`use_frameworks!`) generates an umbrella header that includes all public headers. Under Swift Package Manager, the public header is exposed via the package's `include` directory. In both cases, Swift code sees C functions (like `DTNCollectNativeSignalsJSON`) automatically — no manual bridging header is needed.

### Why don't I see RWX segments on some devices?

- **iOS**: Apple enforces **W^X** (Write XOR Execute) on modern devices. RWX segments are rare and typically indicate a jailbreak or Frida injection.
- **Simulator**: Memory layout differs; RWX signals may not appear as expected.

### Does this work on physical devices only?

No—it works on both **emulators/simulators** and **physical devices**. However:

- Emulators are flagged as `emulator: true`.
- Some signals (like anti-debug `ptrace`) are only active on physical devices in Release mode.

### Can I customize detection thresholds?

Currently, thresholds are hardcoded in the native layer. A future version may expose configuration options (e.g., RWX segment count threshold).

---

## Roadmap

- [ ] Additional signals (USB debugging status, system integrity checks)
- [ ] Configurable thresholds (e.g., adjust RWX segment sensitivity)
- [ ] Optional policy/example UI as a separate package
- [ ] Linux/Windows/macOS support (community contribution welcome)

---

## Contributing

Contributions are welcome! Please:

1. Fork the repo
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for guidelines.

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

## Support

- **Issues**: [GitHub Issues](https://github.com/MuhammedErdemKazanci/device_trust/issues)
- **Repository**: [github.com/MuhammedErdemKazanci/device_trust](https://github.com/MuhammedErdemKazanci/device_trust)

---

Built with ❤️ for Flutter security
