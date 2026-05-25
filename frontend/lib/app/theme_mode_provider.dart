import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/local_cache.dart';

/// App theme mode, persisted locally. Defaults to [ThemeMode.system] (follows
/// the OS) until the user flips the Settings "Dark mode" switch, after which the
/// explicit choice sticks across launches.
class ThemeModeController extends Notifier<ThemeMode> {
  static const _kOverride = 'theme_override';
  static const _kDark = 'theme_dark';

  @override
  ThemeMode build() {
    if (!LocalCache.getBool(_kOverride)) return ThemeMode.system;
    return LocalCache.getBool(_kDark, defaultValue: true)
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  /// Explicitly pick dark or light (used by the Settings toggle).
  Future<void> setDark(bool dark) async {
    state = dark ? ThemeMode.dark : ThemeMode.light;
    await LocalCache.setBool(_kOverride, true);
    await LocalCache.setBool(_kDark, dark);
  }

  /// Revert to following the OS appearance.
  Future<void> useSystem() async {
    state = ThemeMode.system;
    await LocalCache.setBool(_kOverride, false);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
