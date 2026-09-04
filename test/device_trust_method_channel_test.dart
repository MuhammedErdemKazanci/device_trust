import 'package:device_trust/device_trust.dart';
import 'package:device_trust/device_trust_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('device_trust');
  late MethodChannelDeviceTrust platform;

  setUp(() {
    platform = MethodChannelDeviceTrust();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> respondWith(Object? response) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getDeviceTrustReport');
          return response;
        });
  }

  group('getReportRaw', () {
    test('decodes the compact version 1 payload', () async {
      await respondWith([
        1,
        DeviceTrustFlag.rootedOrJailbroken.mask |
            DeviceTrustFlag.fridaSuspected.mask |
            DeviceTrustFlag.debuggerAttached.mask,
        {
          'nativeScanTimeMs': 7,
          'hits': ['example'],
        },
      ]);

      expect(await platform.getReportRaw(), {
        'rootedOrJailbroken': true,
        'emulator': false,
        'devModeEnabled': false,
        'adbEnabled': false,
        'fridaSuspected': true,
        'debuggerAttached': true,
        'details': {
          'nativeScanTimeMs': 7,
          'hits': ['example'],
        },
      });
    });

    for (final flag in DeviceTrustFlag.values) {
      test('maps ${flag.name} to only its matching boolean', () async {
        await respondWith([1, flag.mask, <String, Object?>{}]);

        final result = await platform.getReportRaw();

        expect(
          result['rootedOrJailbroken'],
          flag == DeviceTrustFlag.rootedOrJailbroken,
        );
        expect(result['emulator'], flag == DeviceTrustFlag.emulator);
        expect(
          result['devModeEnabled'],
          flag == DeviceTrustFlag.devModeEnabled,
        );
        expect(result['adbEnabled'], flag == DeviceTrustFlag.adbEnabled);
        expect(
          result['fridaSuspected'],
          flag == DeviceTrustFlag.fridaSuspected,
        );
        expect(
          result['debuggerAttached'],
          flag == DeviceTrustFlag.debuggerAttached,
        );
      });
    }

    test('ignores unknown high bits for forward compatibility', () async {
      await respondWith([
        1,
        (1 << 20) | DeviceTrustFlag.emulator.mask,
        <String, Object?>{},
      ]);

      final result = await platform.getReportRaw();

      expect(result['emulator'], isTrue);
      expect(result['rootedOrJailbroken'], isFalse);
      expect(result['debuggerAttached'], isFalse);
    });

    test('accepts and normalizes a legacy verbose map', () async {
      await respondWith(<Object?, Object?>{
        'rootedOrJailbroken': true,
        'emulator': false,
        'devModeEnabled': true,
        'adbEnabled': false,
        'fridaSuspected': true,
        'debuggerAttached': false,
        'details': {'legacy': true},
        7: 'preserved',
      });

      final result = await platform.getReportRaw();

      expect(result, {
        'rootedOrJailbroken': true,
        'emulator': false,
        'devModeEnabled': true,
        'adbEnabled': false,
        'fridaSuspected': true,
        'debuggerAttached': false,
        'details': {'legacy': true},
        '7': 'preserved',
      });
    });

    test('keeps the existing null-result error', () async {
      await respondWith(null);

      await expectLater(
        platform.getReportRaw(),
        throwsA(
          isA<PlatformException>()
              .having((error) => error.code, 'code', 'NULL_RESULT')
              .having(
                (error) => error.message,
                'message',
                'device_trust returned null',
              ),
        ),
      );
    });

    final invalidPayloads = <(String, Object?)>[
      ('a scalar payload', 'do-not-leak-scalar'),
      ('a short list', [1, 0]),
      ('a long list', [1, 0, <String, Object?>{}, 'do-not-leak-extra']),
      (
        'a non-integer version',
        ['do-not-leak-version', 0, <String, Object?>{}],
      ),
      (
        'an unsupported version',
        [
          2,
          0,
          {'secret': 'do-not-leak'},
        ],
      ),
      ('a non-integer flag set', [1, 'do-not-leak-flags', <String, Object?>{}]),
      (
        'a negative flag set',
        [
          1,
          -1,
          {'secret': 'do-not-leak'},
        ],
      ),
      ('non-map details', [1, 0, 'do-not-leak-details']),
      (
        'details with a non-string key',
        [
          1,
          0,
          {7: 'do-not-leak-key'},
        ],
      ),
    ];

    for (final invalidPayload in invalidPayloads) {
      test('rejects ${invalidPayload.$1} without leaking it', () async {
        await respondWith(invalidPayload.$2);

        await expectLater(
          platform.getReportRaw(),
          throwsA(
            isA<PlatformException>()
                .having((error) => error.code, 'code', 'INVALID_REPORT_PAYLOAD')
                .having(
                  (error) => error.message,
                  'message',
                  'device_trust returned an invalid report payload',
                )
                .having(
                  (error) => '${error.message}${error.details}',
                  'serialized error',
                  isNot(contains('do-not-leak')),
                ),
          ),
        );
      });
    }
  });

  group('isSupported', () {
    test('returns true when the native method responds', () async {
      await respondWith([1, 0, <String, Object?>{}]);

      expect(await platform.isSupported(), isTrue);
    });

    test('returns false when the plugin is missing', () async {
      expect(await platform.isSupported(), isFalse);
    });

    test('returns true when the native platform reports an error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
            throw PlatformException(code: 'NATIVE_ERROR');
          });

      expect(await platform.isSupported(), isTrue);
    });
  });
}
