import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/chat.dart';
import '../../../../core/network/realtime_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/chat_service.dart';
import '../../domain/providers/chat_provider.dart';

/// 1:1 conversation. Messages load over REST; outgoing messages are appended
/// optimistically and incoming ones arrive via the realtime channel.
class ChatScreen extends ConsumerStatefulWidget {
  final String threadId;
  final String? recipientId;
  final String? recipientName;
  final String? bookingId;

  const ChatScreen({
    super.key,
    required this.threadId,
    this.recipientId,
    this.recipientName,
    this.bookingId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  StreamSubscription<RealtimeEvent>? _rt;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Mark the thread read and wire realtime.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatServiceProvider).markRead(widget.threadId).ignore();
    });
    final client = ref.read(realtimeClientProvider);
    client.subscribePrivate('chat.thread.${widget.threadId}');
    _rt = client.events.listen((event) {
      if (event.channel.contains(widget.threadId) && event.data.isNotEmpty) {
        try {
          final message = ChatMessage.fromJson(event.data);
          ref
              .read(chatMessagesProvider(widget.threadId).notifier)
              .append(message);
          _scrollToBottom();
        } catch (_) {/* ignore malformed frames */}
      }
    });
  }

  @override
  void dispose() {
    _rt?.cancel();
    ref
        .read(realtimeClientProvider)
        .unsubscribe('chat.thread.${widget.threadId}');
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || widget.recipientId == null) return;
    _input.clear();
    setState(() => _sending = true);
    try {
      final message = await ref.read(chatServiceProvider).send(
            recipientId: widget.recipientId!,
            content: text,
            bookingId: widget.bookingId,
          );
      ref.read(chatMessagesProvider(widget.threadId).notifier).append(message);
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not send message.')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.threadId));
    final me = ref.watch(currentUserIdProvider) ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(widget.recipientName ?? 'Chat')),
      body: Column(
        children: [
          Expanded(
            child: AsyncValueView<List<ChatMessage>>(
              value: messages,
              onRetry: () => ref
                  .read(chatMessagesProvider(widget.threadId).notifier)
                  .load(),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyView(
                    icon: Icons.waving_hand_outlined,
                    title: 'Say hi! 👋',
                    subtitle: 'Start the conversation.',
                  );
                }
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(Spacing.x4),
                  itemCount: list.length,
                  itemBuilder: (_, i) =>
                      _Bubble(message: list[i], isMine: list[i].isFromMe(me)),
                );
              },
            ),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _composer() {
    final canSend = widget.recipientId != null;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(Spacing.x2),
        decoration: const BoxDecoration(
          color: BrandColors.surface,
          border: Border(top: BorderSide(color: BrandColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                enabled: canSend,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: canSend ? 'Message…' : 'Read-only conversation',
                  filled: true,
                  fillColor: BrandColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.pill),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: Spacing.x4, vertical: Spacing.x2),
                ),
              ),
            ),
            const SizedBox(width: Spacing.x2),
            IconButton.filled(
              onPressed: canSend && !_sending ? _send : null,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: BrandColors.primaryFg))
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  const _Bubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMine ? BrandColors.primary : BrandColors.surface2,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(Radii.md),
            topRight: const Radius.circular(Radii.md),
            bottomLeft: Radius.circular(isMine ? Radii.md : 4),
            bottomRight: Radius.circular(isMine ? 4 : Radii.md),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMine ? BrandColors.primaryFg : BrandColors.foreground,
              ),
            ),
            if (message.createdAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  Formatters.time(message.createdAt!),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMine
                        ? BrandColors.primaryFg.withValues(alpha: 0.7)
                        : BrandColors.mutedFg,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
