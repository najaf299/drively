import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/error_handler.dart';
import '../../../core/utils/json_utils.dart';

/// Mirror of the backend `SettingsController` payload — every value the in-app
/// Settings screen reads, in one bundle. Lists of section/channel keys are
/// declared inline by the UI; the service is just a typed pipe.
class AppSettings {
  final String language; // 'en' | 'ar' | …
  final String currency; // 'AED' | 'USD' | …
  final String units; // 'km' | 'mi'
  final String themeMode; // 'light' | 'dark' | 'system'
  final Map<String, Map<String, bool>> notifications;
  final Map<String, dynamic> privacy;

  const AppSettings({
    required this.language,
    required this.currency,
    required this.units,
    required this.themeMode,
    required this.notifications,
    required this.privacy,
  });

  AppSettings copyWith({
    String? language,
    String? currency,
    String? units,
    String? themeMode,
    Map<String, Map<String, bool>>? notifications,
    Map<String, dynamic>? privacy,
  }) {
    return AppSettings(
      language: language ?? this.language,
      currency: currency ?? this.currency,
      units: units ?? this.units,
      themeMode: themeMode ?? this.themeMode,
      notifications: notifications ?? this.notifications,
      privacy: privacy ?? this.privacy,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final notif = <String, Map<String, bool>>{};
    final raw = asMap(json['notification_settings']) ?? const {};
    raw.forEach((channel, value) {
      if (value is Map) {
        notif[channel] = {
          for (final e in value.entries) e.key.toString(): e.value == true,
        };
      }
    });
    return AppSettings(
      language: asString(json['preferred_language'], fallback: 'en'),
      currency: asString(json['preferred_currency'], fallback: 'USD'),
      units: asString(json['preferred_units'], fallback: 'km'),
      themeMode: asString(json['theme_mode'], fallback: 'system'),
      notifications: notif,
      privacy: asMap(json['privacy_settings']) ?? <String, dynamic>{},
    );
  }
}

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(ref.read(dioProvider));
});

class SettingsService {
  final Dio _dio;
  SettingsService(this._dio);

  Future<AppSettings> fetch() async {
    try {
      final res = await _dio.get(ApiEndpoints.settings);
      return AppSettings.fromJson(
          Map<String, dynamic>.from(ApiResponse.data(res.data) as Map));
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Patches one or more sections — the server merges JSON bags so omitted
  /// keys are preserved.
  Future<AppSettings> update(Map<String, dynamic> patch) async {
    try {
      final res = await _dio.put(ApiEndpoints.settings, data: patch);
      return AppSettings.fromJson(
          Map<String, dynamic>.from(ApiResponse.data(res.data) as Map));
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> signOutEverywhere() async {
    try {
      await _dio.post(ApiEndpoints.signOutAll);
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> deleteAccount({String? password, bool fromOauth = false}) async {
    try {
      await _dio.delete(
        ApiEndpoints.deleteAccount,
        data: {
          if (password != null) 'password': password,
          if (fromOauth) 'from_oauth': true,
        },
      );
    } catch (e) {
      throw mapError(e);
    }
  }
}
