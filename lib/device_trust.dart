// Public Dart API for device_trust: typed model + convenience methods.
import 'dart:async';
import 'device_trust_flag.dart';
import 'device_trust_platform_interface.dart';

export 'device_trust_flag.dart';

/// Device trust report containing security signals from the native platform.
///
/// This model aggregates heuristic detection results for compromised devices:
/// - Root/jailbreak detection
/// - Emulator/simulator detection
/// - Hook/Frida framework detection
/// - Debugger attachment detection
/// - Developer mode and ADB status (Android only)
///
/// Missing or invalid fields in a raw platform report default to safe values.
/// The outer [DeviceTrust.getReport] timeout still throws a [TimeoutException].
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

  /// Compact bit-set representation of the six boolean security signals.
  ///
  /// Use [hasFlag] when checking a single signal. The existing boolean fields
  /// remain the source of truth for the public report model.
  int get flags {
    var value = 0;
    if (rootedOrJailbroken) {
      value |= DeviceTrustFlag.rootedOrJailbroken.mask;
    }
    if (emulator) {
      value |= DeviceTrustFlag.emulator.mask;
    }
    if (devModeEnabled) {
      value |= DeviceTrustFlag.devModeEnabled.mask;
    }
    if (adbEnabled) {
      value |= DeviceTrustFlag.adbEnabled.mask;
    }
    if (fridaSuspected) {
      value |= DeviceTrustFlag.fridaSuspected.mask;
    }
    if (debuggerAttached) {
      value |= DeviceTrustFlag.debuggerAttached.mask;
    }
    return value;
  }

  /// Whether this report contains [flag].
  bool hasFlag(DeviceTrustFlag flag) => flags & flag.mask != 0;

  /// Constructs a [DeviceTrustReport] from a raw map returned by the platform.
  ///
  /// Missing or invalid fields default to safe values (`false` for booleans,
  /// empty map for details).
  factory DeviceTrustReport.fromMap(Map<String, Object?> map) {
    final rawDetails = map['details'];
    final details =
        rawDetails is Map && rawDetails.keys.every((key) => key is String)
        ? Map<String, dynamic>.from(rawDetails)
        : <String, dynamic>{};

    return DeviceTrustReport(
      rootedOrJailbroken: map['rootedOrJailbroken'] == true,
      emulator: map['emulator'] == true,
      devModeEnabled: map['devModeEnabled'] == true,
      adbEnabled: map['adbEnabled'] == true,
      fridaSuspected: map['fridaSuspected'] == true,
      debuggerAttached: map['debuggerAttached'] == true,
      details: details,
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
          throw TimeoutException('device_trust: getReport timeout'),
    );

    return DeviceTrustReport.fromMap(raw);
  }

  /// Returns `true` if the current platform supports this plugin.
  ///
  /// Checks whether the native implementation responds to method calls.
  /// Useful for conditional feature gating.
  static Future<bool> isSupported() =>
      DeviceTrustPlatform.instance.isSupported();
}
