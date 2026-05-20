import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/chat.dart';
import '../../data/chat_service.dart';

/// Conversation threads for the current user (newest activity first).
final threadsProvider =
    FutureProvider.autoDispose<List<ChatThread>>((ref) async {
  final result = await ref.watch(chatServiceProvider).threads();
  return result.items;
});

/// Holds the message list for a single thread (oldest → newest) and supports
/// optimistic/realtime appends.
class ChatNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatService _service;
  final String threadId;

  ChatNotifier(this._service, this.threadId)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final page = await _service.messages(threadId);
      // API returns newest-first; display oldest-first.
      state = AsyncValue.data(page.items.reversed.toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Adds a message (from send response or a realtime event), de-duplicated by id.
  void append(ChatMessage message) {
    final current = state.valueOrNull ?? const <ChatMessage>[];
    if (current.any((m) => m.id == message.id)) return;
    state = AsyncValue.data([...current, message]);
  }
}

final chatMessagesProvider = StateNotifierProvider.family<ChatNotifier,
    AsyncValue<List<ChatMessage>>, String>((ref, threadId) {
  return ChatNotifier(ref.watch(chatServiceProvider), threadId);
});
