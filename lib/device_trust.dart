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
  /// Compact bit-set representation of the report's security signals.
  ///
  /// This is the stored source of truth for the boolean accessors. Use
  /// [hasFlag] when checking a single signal.
  final int flags;

  /// Device is rooted (Android) or jailbroken (iOS).
  ///
  /// Detected via file path checks, su binaries, root management apps,
  /// sandbox escape tests, and URL scheme queries.
  bool get rootedOrJailbroken => hasFlag(DeviceTrustFlag.rootedOrJailbroken);

  /// Running on an emulator (Android) or simulator (iOS).
  ///
  /// Detected via build properties, hardware characteristics, and
  /// compile-time checks (iOS).
  bool get emulator => hasFlag(DeviceTrustFlag.emulator);

  /// Developer mode is enabled (Android only; always `false` on iOS).
  ///
  /// Reflects the system's "Developer options" setting.
  bool get devModeEnabled => hasFlag(DeviceTrustFlag.devModeEnabled);

  /// ADB debugging is enabled (Android only; always `false` on iOS).
  ///
  /// Indicates whether USB debugging is active.
  bool get adbEnabled => hasFlag(DeviceTrustFlag.adbEnabled);

  /// Frida or other hooking framework is suspected.
  ///
  /// Detected via native memory scanning (RWX segments, suspicious libraries,
  /// DYLD image analysis, environment variables).
  bool get fridaSuspected => hasFlag(DeviceTrustFlag.fridaSuspected);

  /// Debugger is attached to the current process.
  ///
  /// Detected via system calls (Android: TracerPid, iOS: sysctl P_TRACED).
  bool get debuggerAttached => hasFlag(DeviceTrustFlag.debuggerAttached);

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
    required bool rootedOrJailbroken,
    required bool emulator,
    required bool devModeEnabled,
    required bool adbEnabled,
    required bool fridaSuspected,
    required bool debuggerAttached,
    required this.details,
  }) : flags =
           (rootedOrJailbroken ? 1 : 0) |
           (emulator ? 2 : 0) |
           (devModeEnabled ? 4 : 0) |
           (adbEnabled ? 8 : 0) |
           (fridaSuspected ? 16 : 0) |
           (debuggerAttached ? 32 : 0);

  const DeviceTrustReport._({required this.flags, required this.details});

  /// Whether this report contains [flag].
  bool hasFlag(DeviceTrustFlag flag) => flag.isSetIn(flags);

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

    final rawFlags = map['flags'];

    return DeviceTrustReport._(
      flags: rawFlags is int && rawFlags >= 0
          ? rawFlags
          : _flagsFromLegacyMap(map),
      details: details,
    );
  }

  static int _flagsFromLegacyMap(Map<String, Object?> map) {
    var flags = 0;
    if (map['rootedOrJailbroken'] == true) {
      flags |= DeviceTrustFlag.rootedOrJailbroken.mask;
    }
    if (map['emulator'] == true) {
      flags |= DeviceTrustFlag.emulator.mask;
    }
    if (map['devModeEnabled'] == true) {
      flags |= DeviceTrustFlag.devModeEnabled.mask;
    }
    if (map['adbEnabled'] == true) {
      flags |= DeviceTrustFlag.adbEnabled.mask;
    }
    if (map['fridaSuspected'] == true) {
      flags |= DeviceTrustFlag.fridaSuspected.mask;
    }
    if (map['debuggerAttached'] == true) {
      flags |= DeviceTrustFlag.debuggerAttached.mask;
    }
    return flags;
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
