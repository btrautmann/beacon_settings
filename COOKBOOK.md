# Beacon Settings Cookbook

This cookbook provides examples of how to use `beacon_settings` in various scenarios.

## Table of Contents

- [Using with `SharedPreferences`](#using-with-sharedpreferences)
- [Observing from a Flutter `Widget`](#observing-from-a-flutter-widget)
- [Using `derivedSetting`](#using-derivedsetting)

### Using with `SharedPreferences`

First, create an implementation of `Storage` that uses `SharedPreferences`.

```dart
class SharedPrefsStorage implements Storage {
  SharedPrefsStorage(SharedPreferences preferences) : _sharedPreferences = preferences;

  final SharedPreferences _sharedPreferences;

  @override
  Object? get(String key) {
    return _sharedPreferences.get(key);
  }

  @override
  Future<void> remove(String key) {
    return _sharedPreferences.remove(key);
  }

  @override
  Future<void> setBool(String key, bool value) {
    return _sharedPreferences.setBool(key, value);
  }

  @override
  Future<void> setDouble(String key, double value) {
    return _sharedPreferences.setDouble(key, value);
  }

  @override
  Future<void> setInt(String key, int value) {
    return _sharedPreferences.setInt(key, value);
  }

  @override
  Future<void> setString(String key, String value) {
    return _sharedPreferences.setString(key, value);
  }

  @override
  Future<void> setStringList(String key, List<String> value) {
    return _sharedPreferences.setStringList(key, value);
  }
}
```

Next, create a `Settings` class that uses the `SharedPrefsStorage`.

```dart
class MySettings extends Settings {
  MySettings(SharedPrefsStorage storage) : super(storage);

  late final isAwesome = setting(
    key: 'isAwesome',
    decode: boolDecoder(defaultValue: true),
    encode: boolEncoder(),
  ).value;
}
```

Finally, use the `MySettings` class in your application.

```dart
void main() async {
  final preferences = await SharedPreferences.getInstance();
  final settings = MySettings(SharedPrefsStorage(preferences));

  print(settings.isAwesome.value); // Prints the value of `isAwesome` from SharedPreferences.
}
```

### Observing from a Flutter `Widget`

To observe a setting from a Flutter `Widget`, use `watch` from `state_beacon`.

```dart
class MyWidget extends StatelessWidget {
  const MyWidget({super.key, required this.settings});

  final MySettings settings;

  @override
  Widget build(BuildContext context) {
    final isAwesome = settings.isAwesome.watch(context);
    return Text(isAwesome.toString());
  }
}
```

### Using `derivedSetting`

`derivedSetting` allows you to create a setting that is derived from other settings.

```dart
class MySettings extends Settings {
  MySettings(Storage storage) : super(storage);

  late final isAwesome = setting(
    key: 'isAwesome',
    decode: boolDecoder(defaultValue: true),
    encode: boolEncoder(),
  ).value;

  // `isNotAwesome` is derived from `isAwesome`. 
  late final isNotAwesome = derivedSetting(
    key: 'isNotAwesome',
    decode: (value, isAwesomeValue) {
      return !isAwesomeValue;
    },
    encode: boolEncoder(),
  ).value;
}
```