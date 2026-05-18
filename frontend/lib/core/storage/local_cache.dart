import 'package:hive_flutter/hive_flutter.dart';

class LocalCache {
  static Future<void> init() async {
    await Hive.initFlutter();
  }

  static Future<Box<T>> openBox<T>(String name) async {
    return await Hive.openBox<T>(name);
  }
}
