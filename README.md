<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

# Beacon Settings

![CI](https://github.com/btrautmann/beacon_settings/actions/workflows/dart.yml/badge.svg)
[![codecov](https://codecov.io/gh/btrautmann/beacon_settings/graph/badge.svg?token=MXT6227EXW)](https://codecov.io/gh/btrautmann/beacon_settings)

A light-weight companion package to [state_beacon](https://pub.dev/packages/state_beacon/example) that provides a simple way to manage settings for a dart application.

## Example usage

```dart
void main() {
  // Create a new instance of `MySettings` with an in-memory storage.
  final settings = MySettings(InMemoryStorage());

  // Print the current value of `isAwesome`. Since the `defaultValue` is true,
  // this is `true` on first access.
  print(settings.isAwesome.value); // Prints `true`

  // Change the value. In this case, use `state_beacon`s built-in `toggle` method.
  settings.isAwesome.toggle();

  // Print the new value of `isAwesome`.
  print(settings.isAwesome.value); // Prints `false`
}

class MySettings extends Settings {
  MySettings(super.storage);

  late final isAwesome = setting(
    key: 'isAwesome',
    decode: boolDecoder(defaultValue: true),
    encode: boolEncoder(),
  ).value;
}
```

## Features

- **Simple**: Define a setting with a key, a decoder, and an encoder.
- **Type-safe**: Decoders and encoders are type-safe.
- **Flexible**: Use the built-in decoders and encoders or define your own.
- **Extensible**: Define your own Storage implementation.
- **Testable**: Use the built-in InMemoryStorage for testing.
- **Compatible**: Plug & play with other `Beacon`s (see `derivedSetting`) and storage implementations like `SharedPreferences`.

## Installation

```sh
dart pub add beacon_settings
```
