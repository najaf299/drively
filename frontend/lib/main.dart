import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'core/storage/local_cache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local offline cache / settings (Hive).
  await LocalCache.init();

  // Read the onboarding flag synchronously so the router can decide the first
  // route without an async gap.
  final onboardingSeen = LocalCache.getBool('onboarding_done');

  runApp(
    ProviderScope(
      overrides: [
        onboardingSeenProvider.overrideWith((ref) => onboardingSeen),
      ],
      child: const DrivlyApp(),
    ),
  );
}
