import 'package:hive_flutter/hive_flutter.dart';

/// Lightweight local cache / key-value settings backed by Hive.
class LocalCache {
  LocalCache._();

  static const _settingsBox = 'settings';

  /// Initialise Hive and open the settings box. Call once at startup.
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_settingsBox);
  }

  static Box get _settings => Hive.box(_settingsBox);

  static bool getBool(String key, {bool defaultValue = false}) =>
      _settings.get(key, defaultValue: defaultValue) as bool;

  static Future<void> setBool(String key, bool value) =>
      _settings.put(key, value);

  static String? getString(String key) => _settings.get(key) as String?;

  static Future<void> setString(String key, String value) =>
      _settings.put(key, value);

  static Future<void> remove(String key) => _settings.delete(key);

  static List<String> getStringList(String key) {
    final raw = _settings.get(key);
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  static Future<void> setStringList(String key, List<String> value) =>
      _settings.put(key, value);

  /// Opens (or returns) a typed box for feature-specific caching.
  static Future<Box<T>> openBox<T>(String name) => Hive.openBox<T>(name);
}
