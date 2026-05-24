import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/chat.dart';
import '../../data/chat_service.dart';

/// Conversation threads for the current user (newest activity first).
final threadsProvider =
    FutureProvider.autoDispose<List<ChatThread>>((ref) async {
  final result = await ref.watch(chatServiceProvider).threads();
  return result.items;
});

/// Client-side archive/delete state for the conversation list. (There is no
/// backend endpoint for this yet, so it's kept in-session — survives tab
/// switches but resets on a cold start.)
@immutable
class ChatListState {
  final Set<String> archived;
  final Set<String> deleted;
  final bool showArchived;

  const ChatListState({
    this.archived = const {},
    this.deleted = const {},
    this.showArchived = false,
  });

  ChatListState copyWith({
    Set<String>? archived,
    Set<String>? deleted,
    bool? showArchived,
  }) =>
      ChatListState(
        archived: archived ?? this.archived,
        deleted: deleted ?? this.deleted,
        showArchived: showArchived ?? this.showArchived,
      );
}

class ChatListController extends StateNotifier<ChatListState> {
  ChatListController() : super(const ChatListState());

  void archive(String id) =>
      state = state.copyWith(archived: {...state.archived, id});

  void unarchive(String id) =>
      state = state.copyWith(archived: {...state.archived}..remove(id));

  void delete(String id) =>
      state = state.copyWith(deleted: {...state.deleted, id});

  void restore(String id) => state = state.copyWith(
        deleted: {...state.deleted}..remove(id),
        archived: {...state.archived}..remove(id),
      );

  void toggleShowArchived() =>
      state = state.copyWith(showArchived: !state.showArchived);
}

/// Not auto-disposed so archive/delete persist while the app is open.
final chatListControllerProvider =
    StateNotifierProvider<ChatListController, ChatListState>(
  (ref) => ChatListController(),
);

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
