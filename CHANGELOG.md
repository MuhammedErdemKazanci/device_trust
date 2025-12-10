# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.1] - 2025-12-10

### Fixed
- Improved Android 15+ compatibility by applying 16KB page-size linker support to all Android ABIs instead of only arm64-v8a.

---

## [1.0.0] - 2025-10-23

### Initial Release

**Platform Support:**
- Android (minSdk 24+)
- iOS (13.0+)

**Android Features:**
- ✅ Root detection (su binaries, Magisk, SuperSU, KingRoot, etc.)
- ✅ Emulator detection (build properties, hardware characteristics)
- ✅ Hook/Frida detection (native C++ memory scanning via JNI)
  - RWX segment analysis
  - Suspicious library detection (Frida, Substrate)
  - File descriptor checks
- ✅ Debugger attachment detection
- ✅ Developer mode & ADB enabled checks
- ✅ Manifest `<queries>` for root management app detection
- ✅ Native C++ library (JNI) for low-level signals
  - ABIs: arm64-v8a, armeabi-v7a, x86_64
- ✅ Fail-soft behavior: returns safe defaults on errors

**iOS Features:**
- ✅ Jailbreak detection
  - File path checks (Cydia, Sileo, Zebra, etc.)
  - Sandbox escape test (write to /private)
  - URL scheme queries (cydia://, sileo://, etc.)
- ✅ Simulator detection (compile-time check)
- ✅ Hook/Frida detection (native Objective-C++ scanning)
  - DYLD image analysis
  - RWX memory segment detection
  - Environment variable checks (DYLD_INSERT_LIBRARIES)
  - libc symbol inspection (hooking detection)
- ✅ Debugger attachment detection (sysctl P_TRACED flag)
- ✅ Anti-debug wrapper (`ptrace(PT_DENY_ATTACH)` in Release + physical device)
- ✅ Native Objective-C++ implementation
- ✅ Fail-soft behavior: returns safe defaults on errors

**Flutter API:**
- ✅ Typed API: `DeviceTrust.getReport()` → `DeviceTrustReport`
- ✅ Model fields:
  - `rootedOrJailbroken: bool`
  - `emulator: bool`
  - `fridaSuspected: bool`
  - `debuggerAttached: bool`
  - `devModeEnabled: bool` (Android only)
  - `adbEnabled: bool` (Android only)
  - `details: Map<String, dynamic>` (platform-specific signals)
- ✅ Platform check: `DeviceTrust.isSupported()`

**Example App:**
- ✅ Production-level diagnostic UI (Material 3)
- ✅ Summary card (color-coded flags)
- ✅ Policy evaluation card (example)
- ✅ Details card (JSON with copy-to-clipboard)
- ✅ Detected signals card (paths, schemes, libraries)
- ✅ Integration test (smoke test)
- ✅ Comprehensive README with platform-specific expectations

**Documentation:**
- ✅ Root README with API reference, platform notes, FAQ
- ✅ Example README with usage instructions
- ✅ MIT License
- ✅ CHANGELOG

**Performance:**
- ✅ Native scans: 1–5 ms typical
- ✅ Total execution: 1–20 ms target

---

## [Unreleased]

### Planned
- Additional signals (USB debugging status, system integrity checks)
- Configurable thresholds (RWX segment sensitivity, timeout values)
- Optional policy/example UI as separate package
- Platform support expansion (macOS, Windows, Linux)
