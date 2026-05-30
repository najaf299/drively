import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings_service.dart';

/// Async-loaded snapshot of the server-side app settings. Listens to the
/// settings service and exposes update helpers that optimistically patch the
/// local state before sending the PUT.
class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final SettingsService _service;

  SettingsNotifier(this._service) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _service.fetch());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
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
    } catch (e, st) {
      // Roll back to the previous server value on failure.
      if (current != null) state = AsyncValue.data(current);
      state = AsyncValue.error(e, st);
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
  return SettingsNotifier(ref.read(settingsServiceProvider));
});
