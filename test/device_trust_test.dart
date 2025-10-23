import 'package:flutter_test/flutter_test.dart';
import 'package:device_trust/device_trust.dart';
import 'package:device_trust/device_trust_platform_interface.dart';

class _FakePlatform extends DeviceTrustPlatform {
  @override
  Future<Map<String, Object?>> getReportRaw() async {
    return {
      'rootedOrJailbroken': true,
      'emulator': false,
      'devModeEnabled': false,
      'adbEnabled': false,
      'fridaSuspected': true,
      'debuggerAttached': false,
      'details': {
        'unit': 'test',
      },
    };
  }

  @override
  Future<bool> isSupported() async => true;
}

void main() {
  test('DeviceTrust.getReport maps to typed model', () async {
    DeviceTrustPlatform.instance = _FakePlatform();

    final r = await DeviceTrust.getReport();
    expect(r.rootedOrJailbroken, isTrue);
    expect(r.emulator, isFalse);
    expect(r.fridaSuspected, isTrue);
    expect(r.details['unit'], 'test');
  });

  test('isSupported forwards', () async {
    DeviceTrustPlatform.instance = _FakePlatform();
    expect(await DeviceTrust.isSupported(), isTrue);
  });
}
