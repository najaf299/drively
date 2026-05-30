import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/profile/data/settings_service.dart';
import '../features/profile/domain/providers/settings_provider.dart';
import '../shared/widgets/drivly_toast.dart';
import 'router.dart';
import 'theme.dart';
import 'theme_mode_provider.dart';

/// Root application widget. Drivly ships both a dark theme (v2) and a light
/// theme ("Daylight", v3), paired via [ThemeMode.system] so the app follows the
/// phone's appearance setting.
class DrivlyApp extends ConsumerWidget {
  const DrivlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Once server settings arrive, mirror the persisted `themeMode` into the
    // local controller so the next cold start paints in the chosen mode
    // before any network call resolves.
    ref.listen<AsyncValue<AppSettings>>(settingsProvider, (prev, next) {
      next.whenData((s) {
        final ctl = ref.read(themeModeProvider.notifier);
        switch (s.themeMode) {
          case 'light':
            if (themeMode != ThemeMode.light) ctl.setDark(false);
          case 'dark':
            if (themeMode != ThemeMode.dark) ctl.setDark(true);
          case 'system':
            if (themeMode != ThemeMode.system) ctl.useSystem();
        }
      });
    });

    return MaterialApp.router(
      title: 'Drivly',
      debugShowCheckedModeBanner: false,
      theme: DrivlyTheme.light,
      darkTheme: DrivlyTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Sync the brand tokens to the active brightness so custom widgets that
        // read BrandColors.* flip too; the KeyedSubtree forces a full rebuild
        // when the OS appearance toggles. Also mounts the DrivlyToast overlay.
        BrandColors.brightness = Theme.of(context).brightness;
        return DrivlyToastHost(
          child: KeyedSubtree(
            key: ValueKey(BrandColors.brightness),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
