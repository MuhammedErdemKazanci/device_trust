# device_trust

[![pub package](https://img.shields.io/pub/v/device_trust.svg)](https://pub.dev/packages/device_trust)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/MuhammedErdemKazanci/device_trust/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/MuhammedErdemKazanci/device_trust/actions/workflows/ci.yml)

**Heuristic Device Integrity Signals for Flutter**

Lightweight detection of compromised devices: **root/jailbreak**, **emulator/simulator**, **hook/Frida**, and **debugger** attachment — for both **Android** and **iOS**. No third-party SDKs.

| iOS | Android |
|-----|---------|
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
|----------|----------------|-------|
| **Android** | API 24+ (Android 7.0) | Kotlin + C++ JNI |
| **iOS** | iOS 13.0+ | Swift 5.0 |

---

## Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  device_trust: ^1.0.0
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
|-------|------|-------------|
| `rootedOrJailbroken` | `bool` | Device is rooted (Android) or jailbroken (iOS) |
| `emulator` | `bool` | Running on emulator/simulator |
| `fridaSuspected` | `bool` | Frida or hooking framework detected |
| `debuggerAttached` | `bool` | Debugger is attached to the process |
| `devModeEnabled` | `bool` | Developer mode enabled (Android only) |
| `adbEnabled` | `bool` | ADB debugging enabled (Android only) |
| `details` | `Map<String, dynamic>` | Platform-specific signals and metadata |

### `DeviceTrust.isSupported()`

Returns `Future<bool>` indicating whether the current platform is supported.

---

## Platform Notes

### Android

- **Manifest Queries**: The plugin's `AndroidManifest.xml` declares `<queries>` for common root management apps (Magisk, SuperSU, etc.) and Frida server. These merge automatically via Gradle—no manual configuration needed.
- **Native Library**: C++ code is compiled into an AAR with the following ABIs:
  - `arm64-v8a` (64-bit ARM)
  - `armeabi-v7a` (32-bit ARM)
  - `x86_64` (64-bit x86)
- **Auto-linking**: CMake/ndk-build handles linking; no additional setup required.
- **Compatibility**: This plugin relies on your app's Android Gradle Plugin (AGP) and Kotlin versions. If you encounter version conflicts during build, align the AGP/Kotlin versions in your app's root `build.gradle` to match the plugin's requirements (typically AGP 8.0+ and Kotlin 1.9+).
- **16KB Page Size Support**: Android devices with 16KB page size are supported (Android 15+ on some devices). The native library is built with `-Wl,-z,max-page-size=16384` for arm64-v8a. We recommend using a modern NDK (r26+) for optimal compatibility.

### iOS

- **URL Schemes**: For jailbreak detection, the plugin checks if certain URL schemes can be opened (`cydia://`, `sileo://`, etc.). Add these to your app's `Info.plist` under `LSApplicationQueriesSchemes`:

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

## Performance & Fail-Soft Behavior

- **Native Scan Duration**: Typically 1–5 ms for file checks, process inspection, and memory analysis.
- **Total Time**: Targets 1–20 ms end-to-end (native + Dart overhead).
- **Fail-Soft**: If the native library fails to load, times out, or throws an error, the plugin returns safe defaults (all flags `false`, empty details). **The app will not crash.**

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

CocoaPods uses framework mode (`use_frameworks!`) and generates an umbrella header that includes all public headers. Swift code in the pod target sees C functions (like `DTNCollectNativeSignalsJSON`) via this umbrella, so no manual bridging header is needed.

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

**Built with ❤️ for Flutter security**
