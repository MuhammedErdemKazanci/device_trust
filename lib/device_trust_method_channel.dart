import 'dart:async';
import 'package:flutter/services.dart';
import 'device_trust_flag.dart';
import 'device_trust_platform_interface.dart';

/// MethodChannel-based implementation of [DeviceTrustPlatform].
///
/// This is the default implementation used by the plugin to communicate
/// with native Android and iOS code via platform channels.
class MethodChannelDeviceTrust extends DeviceTrustPlatform {
  static const int _reportProtocolVersion = 1;

  /// The method channel used to interact with the native platform.
  static const MethodChannel _channel = MethodChannel('device_trust');

  @override
  Future<Map<String, Object?>> getReportRaw() async {
    final Object? result = await _channel.invokeMethod<Object?>(
      'getDeviceTrustReport',
    );

    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'device_trust returned null',
      );
    }

    // Keep accepting the original verbose map during upgrades where the Dart
    // package and native plugin may temporarily be on different versions.
    if (result is Map<Object?, Object?>) {
      return result.map((key, value) => MapEntry(key.toString(), value));
    }

    if (result is! List<Object?> || result.length != 3) {
      throw _invalidReportPayload();
    }

    final version = result[0];
    final flags = result[1];
    final details = result[2];

    if (version is! int ||
        version != _reportProtocolVersion ||
        flags is! int ||
        flags < 0 ||
        details is! Map<Object?, Object?> ||
        details.keys.any((key) => key is! String)) {
      throw _invalidReportPayload();
    }

    return {
      'rootedOrJailbroken': _hasFlag(flags, DeviceTrustFlag.rootedOrJailbroken),
      'emulator': _hasFlag(flags, DeviceTrustFlag.emulator),
      'devModeEnabled': _hasFlag(flags, DeviceTrustFlag.devModeEnabled),
      'adbEnabled': _hasFlag(flags, DeviceTrustFlag.adbEnabled),
      'fridaSuspected': _hasFlag(flags, DeviceTrustFlag.fridaSuspected),
      'debuggerAttached': _hasFlag(flags, DeviceTrustFlag.debuggerAttached),
      'details': Map<String, Object?>.from(details),
    };
  }

  static bool _hasFlag(int flags, DeviceTrustFlag flag) =>
      flags & flag.mask != 0;

  static PlatformException _invalidReportPayload() {
    return PlatformException(
      code: 'INVALID_REPORT_PAYLOAD',
      message: 'device_trust returned an invalid report payload',
    );
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
