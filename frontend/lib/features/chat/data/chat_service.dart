import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/chat.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/error_handler.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.read(dioProvider));
});

/// Chat REST endpoints (`/chat/*`). Realtime delivery is layered on top via the
/// Reverb WebSocket client; this service is the source of truth and fallback.
class ChatService {
  final Dio _dio;
  ChatService(this._dio);

  Future<Paginated<ChatThread>> threads({int page = 1}) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.chatThreads,
        queryParameters: {'page': page},
      );
      return Paginated<ChatThread>.from(
        ApiResponse.data(res.data),
        ChatThread.fromJson,
      );
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Messages for a thread, newest first (matching the API ordering).
  Future<Paginated<ChatMessage>> messages(String threadId,
      {int page = 1}) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.threadMessages(threadId),
        queryParameters: {'page': page},
      );
      return Paginated<ChatMessage>.from(
        ApiResponse.data(res.data),
        ChatMessage.fromJson,
      );
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<ChatMessage> send({
    required String recipientId,
    required String content,
    String? bookingId,
    String type = 'text',
    String? imageUrl,
  }) async {
    try {
      final res = await _dio.post(ApiEndpoints.sendMessage, data: {
        'recipient_id': recipientId,
        'content': content,
        'type': type,
        if (bookingId != null) 'booking_id': bookingId,
        if (imageUrl != null) 'image_url': imageUrl,
      });
      return ChatMessage.fromJson(ApiResponse.data(res.data));
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> markRead(String threadId) async {
    try {
      await _dio.post(ApiEndpoints.markThreadAsRead(threadId));
    } catch (e) {
      throw mapError(e);
    }
  }
}
