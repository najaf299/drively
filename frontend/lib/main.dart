import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/storage/local_cache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local offline cache (Hive).
  await LocalCache.init();

  runApp(const ProviderScope(child: DrivlyApp()));
}
