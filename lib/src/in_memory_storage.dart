import 'package:beacon_settings/src/storage.dart';

/// {@template in_memory_storage}
/// An implementation of [Storage] that stores data in memory.
/// {@endtemplate}
class InMemoryStorage implements Storage {
  final Map<String, dynamic> _data;

  /// {@macro in_memory_storage}
  InMemoryStorage([Map<String, dynamic> initialData = const {}])
      : _data = Map.from(initialData);

  @override
  Object? get(String key) {
    return _data[key];
  }

  @override
  Future<void> remove(String key) async {
    return _data.remove(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    _data[key] = value;
  }

  @override
  Future<void> setDouble(String key, double value) async {
    _data[key] = value;
  }

  @override
  Future<void> setInt(String key, int value) async {
    _data[key] = value;
  }

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    _data[key] = value;
  }
}
