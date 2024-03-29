import 'package:beacon_settings/beacon_settings.dart';
import 'package:state_beacon_core/state_beacon_core.dart';
import 'package:test/test.dart';

void main() {
  group('Settings', () {
    test('setting', () async {
      final storage = InMemoryStorage();
      final settings = TestSettings(storage);

      expect(storage.get('simpleBool'), null);

      // The default value is returned.
      expect(settings.simpleBool.value, false);

      await pumpEventQueue();

      // The default value is encoded and set even though
      // we've never explicitly set it.
      expect(storage.get('simpleBool'), false);

      settings.simpleBool.value = true;

      await pumpEventQueue();

      expect(settings.simpleBool.value, true);

      /// The new value is encoded and set.
      expect(storage.get('simpleBool'), true);
    });

    test('clear', () async {
      final storage = InMemoryStorage();
      final settings = TestSettings(storage);

      settings.simpleBool.value = true;

      await pumpEventQueue();

      expect(storage.get('simpleBool'), true);

      settings.clear();

      await pumpEventQueue();

      /// The default value is encoded and set.
      expect(storage.get('simpleBool'), false);
    });

    test('derived', () async {
      final storage = InMemoryStorage();
      final settings = TestSettings(storage);

      settings.derivedSource.value = 5;

      await pumpEventQueue();

      /// The derived value is calculated (5 + 0).
      expect(settings.derivedSink.value, 5);

      settings.derivedSink.value = 10;

      await pumpEventQueue();

      /// The derived value is calculated (5 + 10).
      expect(settings.derivedSink.value, 15);
    });

    test('allSettings', () async {
      final storage = InMemoryStorage();
      final settings = TestSettings(storage);

      settings.simpleBool.value = true;

      expect(settings.allSettings.value['simpleBool'], true);
      // By default, only settings that have been read/written to are
      // included in `allSettings`.
      expect(settings.allSettings.value.length, 1);

      settings.simpleBool.value = false;

      await pumpEventQueue();

      expect(settings.allSettings.value['simpleBool'], false);
    });

    test('dispose', () async {
      final storage = InMemoryStorage();
      final settings = TestSettings(storage);

      settings.simpleBool.value = true;

      settings.dispose();

      expect(() {
        // state_beacon_core throws as `AssertionError` when updating
        // a disposed beacon.
        settings.simpleBool.value = true;
      }, throwsA(isA<AssertionError>()));
    });

    test('decoders', () async {
      final storage = InMemoryStorage();
      final settings = TestSettings(storage);

      expect(settings.simpleDouble.value, 0.0);
      expect(settings.simpleInt.value, 0);
      expect(settings.simpleString.value, null);
      expect(settings.simpleList.value, <String>[]);

      settings.simpleDouble.value = 1.0;
      settings.simpleInt.value = 1;
      settings.simpleString.value = '1';
      settings.simpleList.value = ['1'];

      await pumpEventQueue();

      expect(settings.simpleDouble.value, 1.0);
      expect(settings.simpleInt.value, 1);
      expect(settings.simpleString.value, '1');
      expect(settings.simpleList.value, ['1']);

      // Test the special null case.
      settings.simpleString.value = null;

      await pumpEventQueue();

      expect(settings.simpleString.value, null);
    });

    test('with initialData', () async {
      final storage = InMemoryStorage({
        'simpleList': ['1']
      });
      final settings = TestSettings(storage);

      expect(settings.simpleList.value, ['1']);

      settings.simpleList.value = ['2'];

      await pumpEventQueue();

      expect(settings.simpleList.value, ['2']);
    });

    test('with invalid type', () async {
      final storage = InMemoryStorage({
        'invalid': Object(),
      });
      final settings = TestSettings(storage);

      expect(
        () => settings.invalid.value,
        throwsA(
          isA<SettingsException>().having(
            (p0) => p0.message,
            'message',
            'Unsupported type: Object',
          ),
        ),
      );
    });

    group('Setting', () {
      test('toggle', () {
        final storage = InMemoryStorage();
        final settings = TestSettings(storage);

        settings.simpleBool.value = true;

        expect(settings.simpleBool.value, true);

        settings.simpleBool.toggle();

        expect(settings.simpleBool.value, false);

        settings.simpleBool.toggle();

        expect(settings.simpleBool.value, true);
      });

      test('reset', () async {
        final storage = InMemoryStorage();
        final settings = TestSettings(storage);

        settings.simpleBool.value = true;

        await pumpEventQueue();

        expect(settings.simpleBool.value, true);

        settings.simpleBool.reset();

        await pumpEventQueue();

        /// The default value is encoded and set.
        expect(settings.simpleBool.value, false);
        expect(storage.get('simpleBool'), false);
      });
    });

    group('RawSettingValue', () {
      test('equals', () {
        expect(BoolSettingValue(true), BoolSettingValue(true));
        expect(BoolSettingValue(true), isNot(BoolSettingValue(false)));

        expect(DoubleSettingValue(1.0), DoubleSettingValue(1.0));
        expect(DoubleSettingValue(1.0), isNot(DoubleSettingValue(2.0)));

        expect(IntSettingValue(1), IntSettingValue(1));
        expect(IntSettingValue(1), isNot(IntSettingValue(2)));

        expect(StringSettingValue('1'), StringSettingValue('1'));
        expect(StringListSettingValue(['1']), StringListSettingValue(['1']));

        expect(NullSettingValue(), NullSettingValue());
      });
    });

    group('SettingsException', () {
      test('toString', () {
        final exception = SettingsException('message');

        expect(exception.toString(), 'SettingsException: message');
      });
    });
  });
}

class TestSettings extends Settings {
  TestSettings(super.storage);

  late final simpleBool = boolSetting(key: 'simpleBool').value;

  late final derivedSource = setting(
    key: 'derivedSource',
    decode: intDecoder(),
    encode: intEncoder(),
  ).value;

  late final derivedSink = derivedSetting(
    key: 'derivedSink',
    input: derivedSource,
    decode: (sinkValue, sourceValue) {
      final sinkValueInt = intDecoder().call(sinkValue);
      return sourceValue + sinkValueInt;
    },
    encode: intEncoder(),
  ).value;

  late final simpleDouble = doubleSetting(key: 'simpleDouble').value;

  late final simpleInt = intSetting(key: 'simpleInt').value;

  late final simpleString = stringSetting(key: 'simpleString').value;

  late final simpleList = stringListSetting(key: 'simpleList').value;

  late final invalid = setting(
    key: 'invalid',
    decode: boolDecoder(),
    encode: boolEncoder(),
  ).value;
}
