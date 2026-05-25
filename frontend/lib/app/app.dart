import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/widgets/drivly_toast.dart';
import 'router.dart';
import 'theme.dart';

/// Root application widget. Drivly is a dark-first product, so a single dark
/// theme is applied regardless of system brightness.
class DrivlyApp extends ConsumerWidget {
  const DrivlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Drivly',
      debugShowCheckedModeBanner: false,
      theme: DrivlyTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      // Mounts the DrivlyToast overlay above every route (incl. sheets/dialogs).
      builder: (context, child) =>
          DrivlyToastHost(child: child ?? const SizedBox.shrink()),
    );
  }
}
