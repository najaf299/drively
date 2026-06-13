import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/settings_service.dart';

/// Async-loaded snapshot of the server-side app settings. Listens to the
/// settings service and exposes update helpers that optimistically patch the
/// local state before sending the PUT.
///
/// The fetch is *gated on authentication* — calling `/settings` before the
/// Sanctum token is restored would 401 and trip the global unauthorized
/// handler, which on cold start fights with the splash/router. So this
/// notifier waits for `authProvider` to flip to `authenticated` before
/// loading; on sign-out it resets to the empty loading state.
class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final SettingsService _service;

  SettingsNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _service.fetch());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Drops back to the empty loading state — used on sign-out so the next
  /// session starts clean.
  void reset() {
    state = const AsyncValue.loading();
  }

  /// Patches one or more top-level fields. Optimistically updates local state,
  /// then reconciles with the server response.
  Future<void> patch(Map<String, dynamic> diff) async {
    final current = state.valueOrNull;
    if (current != null) {
      // Optimistic local update so the UI doesn't flicker.
      state = AsyncValue.data(_apply(current, diff));
    }
    try {
      final fresh = await _service.update(diff);
      state = AsyncValue.data(fresh);
    } catch (e) {
      // Roll back to the last known-good value and rethrow so the caller (the
      // Settings screen) can show a snackbar. Never flip the whole screen into
      // an error state over a single failed toggle.
      if (current != null) state = AsyncValue.data(current);
      rethrow;
    }
  }

  /// Convenience: flip a single notification toggle by `channel.key`
  /// (e.g. "push.bookings", "email.promotions").
  Future<void> toggleNotification(String channel, String key, bool value) async {
    final current = state.valueOrNull;
    final next = <String, Map<String, bool>>{
      ...?current?.notifications,
    };
    next[channel] = {...?next[channel], key: value};
    await patch({
      'notification_settings': {
        channel: {key: value},
      },
    });
  }

  /// Convenience: update one privacy field.
  Future<void> setPrivacy(String key, dynamic value) async {
    await patch({
      'privacy_settings': {key: value},
    });
  }

  AppSettings _apply(AppSettings s, Map<String, dynamic> diff) {
    final notif = <String, Map<String, bool>>{
      for (final e in s.notifications.entries) e.key: {...e.value},
    };
    final raw = diff['notification_settings'];
    if (raw is Map) {
      raw.forEach((channel, value) {
        if (value is Map) {
          notif[channel as String] = {
            ...?notif[channel],
            for (final e in value.entries) e.key.toString(): e.value == true,
          };
        }
      });
    }
    final privacy = <String, dynamic>{...s.privacy};
    final rawPriv = diff['privacy_settings'];
    if (rawPriv is Map) {
      rawPriv.forEach((k, v) => privacy[k.toString()] = v);
    }
    return s.copyWith(
      language: diff['preferred_language'] as String? ?? s.language,
      currency: diff['preferred_currency'] as String? ?? s.currency,
      units: diff['preferred_units'] as String? ?? s.units,
      themeMode: diff['theme_mode'] as String? ?? s.themeMode,
      notifications: notif,
      privacy: privacy,
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
  final notifier = SettingsNotifier(ref.read(settingsServiceProvider));
  // Fetch only when authenticated. On sign-out, drop back to loading so the
  // next sign-in re-fetches with the new user's bag.
  void sync(AuthState s) {
    if (s.isAuthenticated) {
      notifier.refresh();
    } else {
      notifier.reset();
    }
  }
  sync(ref.read(authProvider));
  ref.listen<AuthState>(authProvider, (_, next) => sync(next));
  return notifier;
});
