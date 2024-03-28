import 'package:beacon_settings/src/settings_exception.dart';
import 'package:beacon_settings/src/storage.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:state_beacon_core/state_beacon_core.dart';

/// {@template settings}
/// A class that manages settings. Settings are persisted to an underlying
/// [Storage] implementation. Each setting is represented by a [Setting].
/// {@endtemplate}
abstract class Settings {
  /// {@macro settings}
  Settings(Storage storage) : _storage = storage;

  /// Creates a new [Setting].
  ///
  /// {@macro setting}
  @protected
  Setting<T> setting<T>({
    required String key,
    required Decoder<T> decode,
    required Encoder<T> encode,
  }) {
    final s = Setting<T>(
      settings: this,
      key: key,
      decode: decode,
      encode: encode,
    );
    // Create a new `Map`, otherwise cache listeners won't be updated
    _cache.value = Map.from(_cache.value..[key] = s);
    return s;
  }

  /// Creates a new [Setting] that manages a [int].
  ///
  /// {@macro setting}
  @protected
  Setting<int> intSetting({
    required String key,
    int defaultValue = 0,
  }) {
    return setting(
      key: key,
      decode: intDecoder(defaultValue: defaultValue),
      encode: intEncoder(),
    );
  }

  /// Creates a new [Setting] that manages a [double].
  ///
  /// {@macro setting}
  @protected
  Setting<double> doubleSetting({
    required String key,
    double defaultValue = 0.0,
  }) {
    return setting(
      key: key,
      decode: doubleDecoder(defaultValue: defaultValue),
      encode: doubleEncoder(),
    );
  }

  /// Creates a new [Setting] that manages a [bool].
  ///
  /// {@macro setting}
  @protected
  Setting<bool> boolSetting({
    required String key,
    bool defaultValue = false,
  }) {
    return setting(
      key: key,
      decode: boolDecoder(defaultValue: defaultValue),
      encode: boolEncoder(),
    );
  }

  /// Creates a new [Setting] that manages a [String].
  ///
  /// {@macro setting}
  @protected
  Setting<String?> stringSetting({
    required String key,
  }) {
    return setting(
      key: key,
      decode: nullableStringDecoder(),
      encode: nullableStringEncoder(),
    );
  }

  /// Creates a new [Setting] that manages a [List<String>].
  ///
  /// {@macro setting}
  @protected
  Setting<List<String>> stringListSetting({
    required String key,
  }) {
    return setting(
      key: key,
      decode: stringListDecoder(),
      encode: stringListEncoder(),
    );
  }

  /// Clears all settings by calling [Setting.reset] on each setting
  /// in the cache.
  void clear() {
    for (final s in _cache.value.values) {
      s.reset();
    }
  }

  /// A [ReadableBeacon] that emits a map of all settings.
  ReadableBeacon<Map<String, dynamic>> get allSettings {
    return _group.derived(
      () {
        final out = <String, dynamic>{};
        for (final entry in _cache.value.entries) {
          final settingBeacon = entry.value.value;
          out[entry.key] = settingBeacon.value;
        }
        return out;
      },
      name: 'allSettings',
    );
  }

  /// Disposes all [Beacon]s associated with this [Settings] instance.
  void dispose() {
    _group.disposeAll();
  }

  final Storage _storage;
  final BeaconGroup _group = BeaconGroup();
  late final _cache = _group.writable(
    <String, Setting>{},
    name: '_settingsCache',
  );
}

/// {@template setting}
/// A single setting that exposes a type [T] to the consuming application.
///
/// The [_key] is a function that returns the key
/// for the setting. The [_decode] function is used to convert the raw value
/// from the underlying storage to the type [T]. The [_encode] function is
/// used to convert the value of type [T] to a raw value that can be stored
/// in the underlying storage.
/// {@endtemplate}
class Setting<T> {
  /// {@macro setting}
  Setting({
    required Settings settings,
    required String key,
    required T Function(RawSettingValue) decode,
    required RawSettingValue Function(T) encode,
  })  : _decode = decode,
        _encode = encode,
        _key = key,
        _settings = settings {
    final $key = _key;
    value = _settings._group.writable(
      _decode(_toRawValue(_settings._storage.get($key))),
      name: '${$key}_value',
    );
    // Any time `value` changes, persist the new value to the underlying storage.
    _settings._group.effect(
      () async {
        final $value = value.value;
        final $key = _key;
        if (_settings._storage.get($key) != $value) {
          final encoded = _encode($value);
          await switch (encoded) {
            StringSettingValue() =>
              _settings._storage.setString($key, encoded.value),
            IntSettingValue() => _settings._storage.setInt($key, encoded.value),
            DoubleSettingValue() =>
              _settings._storage.setDouble($key, encoded.value),
            BoolSettingValue() =>
              _settings._storage.setBool($key, encoded.value),
            StringListSettingValue() =>
              _settings._storage.setStringList($key, encoded.value),
            NullSettingValue() => _settings._storage.remove($key),
          };
        }
      },
      name: '${$key}_effect',
    );
  }

  RawSettingValue _toRawValue(Object? v) {
    return switch (v) {
      String() => StringSettingValue(v),
      int() => IntSettingValue(v),
      double() => DoubleSettingValue(v),
      bool() => BoolSettingValue(v),
      // In some cases, the type of a StringListSetting can be List<Object?>
      // instead of List<String>. This is a workaround to handle that case.
      // Note that the List<String> type also passes this check.
      List<Object?>() => StringListSettingValue(v.toStringList()),
      null => const NullSettingValue(),
      _ => throw SettingsException('Unsupported type: ${v.runtimeType}'),
    };
  }

  /// Resets the setting to its default value by invoking the [_decode] function
  /// with a [NullSettingValue] and setting [value] to the result.
  void reset() {
    value.value = _decode(const NullSettingValue());
  }

  /// The value of the setting. Changing the setting can be done by
  /// assigning a new value to this property. The new value will be
  /// persisted to the underlying storage.
  late final WritableBeacon<T> value;

  final Settings _settings;
  final String _key;
  final Encoder<T> _encode;
  final Decoder<T> _decode;
}

/// A function that converts a value of type `R` to a value of type `T`.
typedef Decoder<T> = T Function(RawSettingValue value);

/// A function that converts a value of type `T` to a value of type `R`.
typedef Encoder<T> = RawSettingValue Function(T);

/// Extension methods for [Settings].
extension SettingsX on Settings {
  /// A [Setting] that is derived from [input]. Any time the [input]
  /// changes, the [decode] function will be invoked with the current
  /// value of the returned [Setting] as well as the new value of [input].
  /// Similarly, any time the returned [Setting] changes, the [decode] function
  /// will be invoked with the new value of the returned [Setting] as well as
  /// the current value of [input].
  ///
  /// This is useful if a [Setting] depends on another [Setting].
  Setting<T> derivedSetting<T, I>({
    required String key,
    required ReadableBeacon<I> input,
    required T Function(RawSettingValue, I) decode,
    required RawSettingValue Function(T) encode,
  }) {
    final s = setting<T>(
      key: key,
      decode: (value) => decode(value, input.value),
      encode: (value) => encode(value),
    );
    _group.effect(
      () {
        final $input = input.value;
        final $s = s.value.value;
        final decoded = decode(s._toRawValue(_storage.get(key)), $input);
        if (decoded != $s) {
          s.value.value = decoded;
        }
      },
      name: 'derivedSettingEffect',
    );
    return s;
  }
}

/// Decoder for a [Setting] that manages an [int]. If the value is not in
/// the underlying [Storage], [defaultValue] is returned.
Decoder<int> intDecoder({int defaultValue = 0}) {
  return (value) => value is IntSettingValue ? value.value : defaultValue;
}

/// Encoder for a [Setting] that manages an [int].
Encoder<int> intEncoder() {
  return IntSettingValue.new;
}

/// Decoder for a [Setting] that manages a [bool]. If the value is not in
/// the underlying [Storage], [defaultValue] is returned.
Decoder<bool> boolDecoder({bool defaultValue = false}) {
  return (value) => (value is BoolSettingValue && value.value) || defaultValue;
}

/// Encoder for a [Setting] that manages a [bool].
Encoder<bool> boolEncoder() {
  return BoolSettingValue.new;
}

/// Decoder for a [Setting] that manages a [String]. If the value is not in
/// the underlying [Storage], `null` is returned.
Decoder<String?> nullableStringDecoder() {
  return (value) => value is! StringSettingValue ? null : value.value;
}

/// Encoder for a [Setting] that manages a [String].
Encoder<String?> nullableStringEncoder() {
  return (value) =>
      value == null ? const NullSettingValue() : StringSettingValue(value);
}

/// Decoder for a [Setting] that manages a [String]. If the value is not in
/// the underlying [Storage], [defaultValue] is returned.
Decoder<double> doubleDecoder({double defaultValue = 0.0}) {
  return (value) => value is DoubleSettingValue ? value.value : defaultValue;
}

/// Encoder for a [Setting] that manages a [double].
Encoder<double> doubleEncoder() {
  return DoubleSettingValue.new;
}

/// Decoder for a [Setting] that manages a [List] of [String]s. If the value
/// is not in the underlying [Storage], an empty [List] is returned.
Decoder<List<String>> stringListDecoder() {
  return (value) => value is! StringListSettingValue ? <String>[] : value.value;
}

/// Encoder for a [Setting] that manages a [List] of [String]s.
Encoder<List<String>> stringListEncoder() {
  return StringListSettingValue.new;
}

/// Base class for raw values extracted from the underlying storage. Used
/// as the input for [Decoder]s and the output for [Encoder]s.
sealed class RawSettingValue extends Equatable {
  const RawSettingValue();
}

/// {@template string_setting_value}
/// A raw value that represents a [String].
/// {@endtemplate}
class StringSettingValue extends RawSettingValue {
  /// {@macro string_setting_value}
  const StringSettingValue(this.value);

  /// The raw [String].
  final String value;

  @override
  List<Object?> get props => [value];
}

/// {@template int_setting_value}
/// A raw value that represents an [int].
/// {@endtemplate}
class IntSettingValue extends RawSettingValue {
  /// {@macro int_setting_value}
  const IntSettingValue(this.value);

  /// The raw [int].
  final int value;

  @override
  List<Object?> get props => [value];
}

/// {@template double_setting_value}
/// A raw value that represents a [double].
/// {@endtemplate}
class DoubleSettingValue extends RawSettingValue {
  /// {@macro double_setting_value}
  const DoubleSettingValue(this.value);

  /// The raw [double].
  final double value;

  @override
  List<Object?> get props => [value];
}

/// {@template bool_setting_value}
/// A raw value that represents a [bool].
/// {@endtemplate}
class BoolSettingValue extends RawSettingValue {
  /// {@macro bool_setting_value}
  const BoolSettingValue(this.value);

  /// The raw [bool].
  final bool value;

  @override
  List<Object?> get props => [value];
}

/// {@template string_list_setting_value}
/// A raw value that represents a [List] of [String]s.
/// {@endtemplate}
class StringListSettingValue extends RawSettingValue {
  /// {@macro string_list_setting_value}
  const StringListSettingValue(this.value);

  /// The raw [List] of [String]s.
  final List<String> value;

  @override
  List<Object?> get props => [value];
}

/// {@template null_setting_value}
/// A raw value that represents `null`.
/// {@endtemplate}
class NullSettingValue extends RawSettingValue {
  /// {@macro null_setting_value}
  const NullSettingValue();

  @override
  List<Object?> get props => [null];
}

extension on List<Object?> {
  List<String> toStringList() {
    return map((e) => e as String?)
        .where((s) => s != null)
        .cast<String>()
        .toList();
  }
}
