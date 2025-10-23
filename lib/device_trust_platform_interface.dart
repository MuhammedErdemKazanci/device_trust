import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'device_trust_method_channel.dart';

/// Platform interface for the device_trust plugin.
///
/// This exposes low-level, raw map results so the public API wrapper
/// ([DeviceTrust]) can provide a typed model ([DeviceTrustReport]).
///
/// Platform-specific implementations should extend this class and override
/// [getReportRaw] and [isSupported].
abstract class DeviceTrustPlatform extends PlatformInterface {
  /// Constructs a [DeviceTrustPlatform].
  DeviceTrustPlatform() : super(token: _token);

  static final Object _token = Object();

  static DeviceTrustPlatform _instance = MethodChannelDeviceTrust();

  /// The default instance of [DeviceTrustPlatform] to use.
  static DeviceTrustPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DeviceTrustPlatform] when
  /// they register themselves.
  static set instance(DeviceTrustPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Collects device trust signals as a raw map.
  ///
  /// Platform implementations should return a map with keys:
  /// - `rootedOrJailbroken` (bool)
  /// - `emulator` (bool)
  /// - `devModeEnabled` (bool)
  /// - `adbEnabled` (bool)
  /// - `fridaSuspected` (bool)
  /// - `debuggerAttached` (bool)
  /// - `details` (`Map<String, dynamic>`)
  Future<Map<String, Object?>> getReportRaw();

  /// Returns `true` if the platform side responds to method calls.
  ///
  /// Used to check if a native implementation is available.
  Future<bool> isSupported();
}
