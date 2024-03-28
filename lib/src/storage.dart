/// An interface used by [Settings] to persist values.
abstract class Storage {
  /// Retrieves the value associated with the given [key].
  Object? get(String key);

  /// Sets the value associated with the given [key] to [value].
  Future<void> setString(String key, String value);

  /// Sets the value associated with the given [key] to [value].
  Future<void> setStringList(String key, List<String> value);

  /// Sets the value associated with the given [key] to [value].
  Future<void> setInt(String key, int value);

  /// Sets the value associated with the given [key] to [value].
  Future<void> setDouble(String key, double value);

  /// Sets the value associated with the given [key] to [value].
  Future<void> setBool(String key, bool value);

  /// Removes the value associated with the given [key].
  Future<void> remove(String key);
}
