import 'package:beacon_settings/beacon_settings.dart';
import 'package:state_beacon_core/state_beacon_core.dart';

void main() {
  final settings = MySettings(InMemoryStorage());

  print(settings.isAwesome.value); // Prints `true`

  settings.isAwesome.toggle();

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
