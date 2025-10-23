import 'package:flutter_test/flutter_test.dart';
import 'package:device_trust/device_trust.dart';
import 'package:device_trust/device_trust_platform_interface.dart';
import 'package:device_trust/device_trust_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDeviceTrustPlatform
    with MockPlatformInterfaceMixin
    implements DeviceTrustPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DeviceTrustPlatform initialPlatform = DeviceTrustPlatform.instance;

  test('$MethodChannelDeviceTrust is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDeviceTrust>());
  });

  test('getPlatformVersion', () async {
    DeviceTrust deviceTrustPlugin = DeviceTrust();
    MockDeviceTrustPlatform fakePlatform = MockDeviceTrustPlatform();
    DeviceTrustPlatform.instance = fakePlatform;

    expect(await deviceTrustPlugin.getPlatformVersion(), '42');
  });
}
