import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'device_trust_platform_interface.dart';

/// An implementation of [DeviceTrustPlatform] that uses method channels.
class MethodChannelDeviceTrust extends DeviceTrustPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('device_trust');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
