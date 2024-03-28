import 'package:beacon_settings/beacon_settings.dart';

/// {@template settings_exception}
/// Exception thrown when there is an error in [Settings].
/// {@endtemplate}
class SettingsException implements Exception {
  /// The error message.
  final String message;

  /// {@macro settings_exception}
  SettingsException(this.message);

  @override
  String toString() => 'SettingsException: $message';
}
