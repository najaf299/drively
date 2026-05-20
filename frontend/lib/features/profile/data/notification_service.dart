import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/notification.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/error_handler.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.read(dioProvider));
});

/// In-app notification inbox + push-device registration (`/notifications/*`).
class NotificationService {
  final Dio _dio;
  NotificationService(this._dio);

  Future<Paginated<AppNotification>> list({
    bool unreadOnly = false,
    int page = 1,
  }) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.notifications,
        queryParameters: {
          if (unreadOnly) 'unread_only': true,
          'page': page,
        },
      );
      return Paginated<AppNotification>.from(
        ApiResponse.data(res.data),
        AppNotification.fromJson,
      );
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.post(ApiEndpoints.markNotificationRead(id));
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post(ApiEndpoints.markAllNotificationsRead);
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> registerDevice(String token, String platform) async {
    try {
      await _dio.post(
        ApiEndpoints.registerDevice,
        data: {'token': token, 'platform': platform},
      );
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> unregisterDevice(String token) async {
    try {
      await _dio.delete(ApiEndpoints.unregisterDevice, data: {'token': token});
    } catch (e) {
      throw mapError(e);
    }
  }
}
