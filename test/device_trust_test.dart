import 'package:device_trust/device_trust.dart';
import 'package:device_trust/device_trust_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePlatform extends DeviceTrustPlatform {
  @override
  Future<Map<String, Object?>> getReportRaw() async {
    return {
      'flags': 17,
      'rootedOrJailbroken': true,
      'emulator': false,
      'devModeEnabled': false,
      'adbEnabled': false,
      'fridaSuspected': true,
      'debuggerAttached': false,
      'details': {'unit': 'test'},
    };
  }

  @override
  Future<bool> isSupported() async => true;
}

void main() {
  test('DeviceTrustFlag masks are stable', () {
    expect(
      {for (final flag in DeviceTrustFlag.values) flag: flag.mask},
      {
        DeviceTrustFlag.rootedOrJailbroken: 1,
        DeviceTrustFlag.emulator: 2,
        DeviceTrustFlag.devModeEnabled: 4,
        DeviceTrustFlag.adbEnabled: 8,
        DeviceTrustFlag.fridaSuspected: 16,
        DeviceTrustFlag.debuggerAttached: 32,
      },
    );

    expect(DeviceTrustFlag.emulator.isSetIn(2), isTrue);
    expect(DeviceTrustFlag.emulator.isSetIn(1), isFalse);
  });

  test('DeviceTrustReport.fromMap defaults all signals', () {
    final report = DeviceTrustReport.fromMap({});

    expect(report.rootedOrJailbroken, isFalse);
    expect(report.emulator, isFalse);
    expect(report.devModeEnabled, isFalse);
    expect(report.adbEnabled, isFalse);
    expect(report.fridaSuspected, isFalse);
    expect(report.debuggerAttached, isFalse);
    expect(report.flags, 0);
    expect(report.details, isEmpty);
  });

  test('DeviceTrustReport.fromMap safely defaults invalid field types', () {
    final report = DeviceTrustReport.fromMap({
      'flags': -1,
      'rootedOrJailbroken': 'true',
      'emulator': 1,
      'devModeEnabled': null,
      'adbEnabled': <Object?>[],
      'fridaSuspected': <String, Object?>{},
      'debuggerAttached': Object(),
      'details': {7: 'non-string key'},
    });

    expect(report.rootedOrJailbroken, isFalse);
    expect(report.emulator, isFalse);
    expect(report.devModeEnabled, isFalse);
    expect(report.adbEnabled, isFalse);
    expect(report.fridaSuspected, isFalse);
    expect(report.debuggerAttached, isFalse);
    expect(report.flags, 0);
    expect(report.details, isEmpty);
  });

  test(
    'DeviceTrustReport stores compact flags and derives boolean accessors',
    () {
      final flags =
          (1 << 20) |
          DeviceTrustFlag.rootedOrJailbroken.mask |
          DeviceTrustFlag.fridaSuspected.mask;
      final report = DeviceTrustReport.fromMap({
        'flags': flags,
        'details': {'source': 'compact'},
      });

      expect(report.flags, flags);
      expect(report.rootedOrJailbroken, isTrue);
      expect(report.emulator, isFalse);
      expect(report.devModeEnabled, isFalse);
      expect(report.adbEnabled, isFalse);
      expect(report.fridaSuspected, isTrue);
      expect(report.debuggerAttached, isFalse);
      expect(report.details, {'source': 'compact'});
    },
  );

  test('DeviceTrustReport.fromMap accepts every legacy boolean field', () {
    final report = DeviceTrustReport.fromMap({
      'rootedOrJailbroken': true,
      'emulator': true,
      'devModeEnabled': true,
      'adbEnabled': true,
      'fridaSuspected': true,
      'debuggerAttached': true,
      'details': {'a': 1},
    });

    expect(report.rootedOrJailbroken, isTrue);
    expect(report.emulator, isTrue);
    expect(report.devModeEnabled, isTrue);
    expect(report.adbEnabled, isTrue);
    expect(report.fridaSuspected, isTrue);
    expect(report.debuggerAttached, isTrue);
    expect(report.flags, 63);
    expect(report.details['a'], 1);
  });

  test('flags and hasFlag reflect constructor boolean values', () {
    const report = DeviceTrustReport(
      rootedOrJailbroken: true,
      emulator: false,
      devModeEnabled: true,
      adbEnabled: false,
      fridaSuspected: true,
      debuggerAttached: false,
      details: {},
    );

    expect(report.flags, 21);
    expect(report.hasFlag(DeviceTrustFlag.rootedOrJailbroken), isTrue);
    expect(report.hasFlag(DeviceTrustFlag.emulator), isFalse);
    expect(report.hasFlag(DeviceTrustFlag.devModeEnabled), isTrue);
    expect(report.hasFlag(DeviceTrustFlag.adbEnabled), isFalse);
    expect(report.hasFlag(DeviceTrustFlag.fridaSuspected), isTrue);
    expect(report.hasFlag(DeviceTrustFlag.debuggerAttached), isFalse);
  });

  test('constructor stores every boolean as its matching flag', () {
    for (final flag in DeviceTrustFlag.values) {
      final report = DeviceTrustReport(
        rootedOrJailbroken: flag == DeviceTrustFlag.rootedOrJailbroken,
        emulator: flag == DeviceTrustFlag.emulator,
        devModeEnabled: flag == DeviceTrustFlag.devModeEnabled,
        adbEnabled: flag == DeviceTrustFlag.adbEnabled,
        fridaSuspected: flag == DeviceTrustFlag.fridaSuspected,
        debuggerAttached: flag == DeviceTrustFlag.debuggerAttached,
        details: const {},
      );

      expect(report.flags, flag.mask);
      for (final candidate in DeviceTrustFlag.values) {
        expect(report.hasFlag(candidate), candidate == flag);
      }
    }
  });

  test('toMap preserves the existing public serialization shape', () {
    const report = DeviceTrustReport(
      rootedOrJailbroken: true,
      emulator: false,
      devModeEnabled: true,
      adbEnabled: false,
      fridaSuspected: true,
      debuggerAttached: false,
      details: {'source': 'test'},
    );

    expect(report.toMap(), {
      'rootedOrJailbroken': true,
      'emulator': false,
      'devModeEnabled': true,
      'adbEnabled': false,
      'fridaSuspected': true,
      'debuggerAttached': false,
      'details': {'source': 'test'},
    });
    expect(report.toMap(), isNot(contains('flags')));
  });

  test('DeviceTrust.getReport maps raw data to the typed model', () async {
    DeviceTrustPlatform.instance = _FakePlatform();

    final report = await DeviceTrust.getReport();

    expect(report.rootedOrJailbroken, isTrue);
    expect(report.emulator, isFalse);
    expect(report.fridaSuspected, isTrue);
    expect(report.flags, 17);
    expect(report.details['unit'], 'test');
  });

  test('isSupported forwards to the platform implementation', () async {
    DeviceTrustPlatform.instance = _FakePlatform();

    expect(await DeviceTrust.isSupported(), isTrue);
  });
}
