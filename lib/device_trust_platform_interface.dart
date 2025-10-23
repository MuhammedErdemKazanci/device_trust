import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'device_trust_method_channel.dart';

abstract class DeviceTrustPlatform extends PlatformInterface {
  /// Constructs a DeviceTrustPlatform.
  DeviceTrustPlatform() : super(token: _token);

  static final Object _token = Object();

  static DeviceTrustPlatform _instance = MethodChannelDeviceTrust();

  /// The default instance of [DeviceTrustPlatform] to use.
  ///
  /// Defaults to [MethodChannelDeviceTrust].
  static DeviceTrustPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DeviceTrustPlatform] when
  /// they register themselves.
  static set instance(DeviceTrustPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
