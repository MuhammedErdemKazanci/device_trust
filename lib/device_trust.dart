// Public Dart API for device_trust: typed model + convenience methods.
import 'dart:async';
import 'device_trust_platform_interface.dart';

/// Device trust report containing security signals from the native platform.
///
/// This model aggregates heuristic detection results for compromised devices:
/// - Root/jailbreak detection
/// - Emulator/simulator detection
/// - Hook/Frida framework detection
/// - Debugger attachment detection
/// - Developer mode and ADB status (Android only)
///
/// All boolean flags default to `false` if the native layer fails or times out
/// (fail-soft behavior).
class DeviceTrustReport {
  /// Device is rooted (Android) or jailbroken (iOS).
  ///
  /// Detected via file path checks, su binaries, root management apps,
  /// sandbox escape tests, and URL scheme queries.
  final bool rootedOrJailbroken;

  /// Running on an emulator (Android) or simulator (iOS).
  ///
  /// Detected via build properties, hardware characteristics, and
  /// compile-time checks (iOS).
  final bool emulator;

  /// Developer mode is enabled (Android only; always `false` on iOS).
  ///
  /// Reflects the system's "Developer options" setting.
  final bool devModeEnabled;

  /// ADB debugging is enabled (Android only; always `false` on iOS).
  ///
  /// Indicates whether USB debugging is active.
  final bool adbEnabled;

  /// Frida or other hooking framework is suspected.
  ///
  /// Detected via native memory scanning (RWX segments, suspicious libraries,
  /// DYLD image analysis, environment variables).
  final bool fridaSuspected;

  /// Debugger is attached to the current process.
  ///
  /// Detected via system calls (Android: TracerPid, iOS: sysctl P_TRACED).
  final bool debuggerAttached;

  /// Platform-specific signals and metadata (e.g., detected paths, libraries).
  ///
  /// Common keys:
  /// - `jbPathHits` (iOS): List of jailbreak paths found
  /// - `urlSchemeHits` (iOS): List of jailbreak URL schemes detected
  /// - `nativeDyldSuspicious` (iOS): List of suspicious DYLD images
  /// - `rwxSegmentCount` (iOS/Android): Number of RWX memory segments
  /// - `nativeScanTimeMs` (both): Native scan duration in milliseconds
  final Map<String, dynamic> details;

  /// Creates a [DeviceTrustReport] with the given fields.
  const DeviceTrustReport({
    required this.rootedOrJailbroken,
    required this.emulator,
    required this.devModeEnabled,
    required this.adbEnabled,
    required this.fridaSuspected,
    required this.debuggerAttached,
    required this.details,
  });

  /// Constructs a [DeviceTrustReport] from a raw map returned by the platform.
  ///
  /// Missing or invalid fields default to safe values (`false` for booleans,
  /// empty map for details).
  factory DeviceTrustReport.fromMap(Map<String, Object?> map) {
    return DeviceTrustReport(
      rootedOrJailbroken: (map['rootedOrJailbroken'] as bool?) ?? false,
      emulator: (map['emulator'] as bool?) ?? false,
      devModeEnabled: (map['devModeEnabled'] as bool?) ?? false,
      adbEnabled: (map['adbEnabled'] as bool?) ?? false,
      fridaSuspected: (map['fridaSuspected'] as bool?) ?? false,
      debuggerAttached: (map['debuggerAttached'] as bool?) ?? false,
      details: Map<String, dynamic>.from((map['details'] as Map?) ?? const {}),
    );
  }

  /// Converts this report to a raw map for serialization.
  Map<String, Object?> toMap() => {
        'rootedOrJailbroken': rootedOrJailbroken,
        'emulator': emulator,
        'devModeEnabled': devModeEnabled,
        'adbEnabled': adbEnabled,
        'fridaSuspected': fridaSuspected,
        'debuggerAttached': debuggerAttached,
        'details': details,
      };

  /// Returns a concise string representation of the main flags.
  @override
  String toString() {
    return 'DeviceTrustReport{rooted=$rootedOrJailbroken, emulator=$emulator, '
        'devMode=$devModeEnabled, adb=$adbEnabled, frida=$fridaSuspected, '
        'debugger=$debuggerAttached}';
  }
}

/// High-level API for collecting device trust signals.
///
/// This class provides static methods to fetch security-related signals
/// from the native Android and iOS implementations.
///
/// Example usage:
/// ```dart
/// final report = await DeviceTrust.getReport();
/// if (report.rootedOrJailbroken || report.fridaSuspected) {
///   print('⚠️  Device integrity compromised');
/// }
/// ```
class DeviceTrust {
  /// Fetches device trust signals from the native platform.
  ///
  /// Returns a [DeviceTrustReport] containing boolean flags and detailed
  /// metadata about the device's security posture.
  ///
  /// The [timeout] parameter sets the maximum wait time (default: 1.5s).
  /// Throws [TimeoutException] if the native call exceeds this duration.
  ///
  /// Example:
  /// ```dart
  /// final report = await DeviceTrust.getReport();
  /// print('Rooted: ${report.rootedOrJailbroken}');
  /// ```
  static Future<DeviceTrustReport> getReport({
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    final raw = await DeviceTrustPlatform.instance.getReportRaw().timeout(
        timeout,
        onTimeout: () =>
            throw TimeoutException('device_trust: getReport timeout'));

    return DeviceTrustReport.fromMap(raw);
  }

  /// Returns `true` if the current platform supports this plugin.
  ///
  /// Checks whether the native implementation responds to method calls.
  /// Useful for conditional feature gating.
  static Future<bool> isSupported() =>
      DeviceTrustPlatform.instance.isSupported();
}
