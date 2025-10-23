import 'package:flutter_test/flutter_test.dart';
import 'package:device_trust/device_trust.dart';

void main() {
  test('DeviceTrustReport.fromMap defaults', () {
    final r = DeviceTrustReport.fromMap({});
    expect(r.rootedOrJailbroken, isFalse);
    expect(r.emulator, isFalse);
    expect(r.fridaSuspected, isFalse);
    expect(r.debuggerAttached, isFalse);
    expect(r.details, isEmpty);
  });

  test('DeviceTrustReport.fromMap fills fields', () {
    final r = DeviceTrustReport.fromMap({
      'rootedOrJailbroken': true,
      'emulator': true,
      'devModeEnabled': true,
      'adbEnabled': true,
      'fridaSuspected': true,
      'debuggerAttached': true,
      'details': {'a': 1}
    });
    expect(r.rootedOrJailbroken, isTrue);
    expect(r.emulator, isTrue);
    expect(r.devModeEnabled, isTrue);
    expect(r.adbEnabled, isTrue);
    expect(r.fridaSuspected, isTrue);
    expect(r.debuggerAttached, isTrue);
    expect(r.details['a'], 1);
  });
}
