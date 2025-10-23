import 'dart:async';
import 'package:flutter/services.dart';
import 'device_trust_platform_interface.dart';

/// MethodChannel-based implementation of [DeviceTrustPlatform].
///
/// This is the default implementation used by the plugin to communicate
/// with native Android and iOS code via platform channels.
class MethodChannelDeviceTrust extends DeviceTrustPlatform {
  /// The method channel used to interact with the native platform.
  static const MethodChannel _channel = MethodChannel('device_trust');

  @override
  Future<Map<String, Object?>> getReportRaw() async {
    final Map<Object?, Object?>? result = await _channel
        .invokeMethod<Map<Object?, Object?>>('getDeviceTrustReport');

    if (result == null) {
      throw PlatformException(
          code: 'NULL_RESULT', message: 'device_trust returned null');
    }

    // Normalize keys to String
    return result.map((key, value) => MapEntry(key.toString(), value));
  }

  @override
  Future<bool> isSupported() async {
    try {
      await _channel.invokeMethod('getDeviceTrustReport');
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      // Platform present but returned an error — still supported.
      return true;
    } catch (_) {
      return false;
    }
  }
}
