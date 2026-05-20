import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(() {
      final has = _input.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _header(),
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
                      itemCount: list.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) return _dateSeparator(list);
                        final m = list[i - 1];
                        return _Bubble(message: m, isMine: m.isFromMe(me));
                      },
                    );
                  },
                ),
              ),
              _composer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final name = widget.recipientName ?? 'Chat';
    final initials = _initials(name);
    return Container(
      padding: const EdgeInsets.fromLTRB(
          Spacing.x4, Spacing.x2, Spacing.x4, Spacing.x2),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: BrandColors.border)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.canPop() ? context.pop() : context.go('/'),
            customBorder: const CircleBorder(),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: BrandColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back,
                  size: 20, color: BrandColors.foreground),
            ),
          ),
          const SizedBox(width: Spacing.x3),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: BrandColors.accent,
              shape: BoxShape.circle,
            ),
            child: Text(
              initials,
              style: const TextStyle(
                color: BrandColors.primaryFg,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: BrandColors.foreground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: BrandColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Online',
                      style: TextStyle(
                          color: BrandColors.success, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.call_outlined,
                color: BrandColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _dateSeparator(List<ChatMessage> list) {
    final ts = list.isNotEmpty ? list.first.createdAt : null;
    final label =
        ts != null ? 'TODAY · ${Formatters.time(ts)}' : 'TODAY';
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: Spacing.x3),
        padding:
            const EdgeInsets.symmetric(horizontal: Spacing.x3, vertical: 5),
        decoration: BoxDecoration(
          color: BrandColors.surface,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: BrandColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: BrandColors.mutedFg,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _composer() {
    final canSend = widget.recipientId != null;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            Spacing.x3, Spacing.x2, Spacing.x3, Spacing.x2),
        decoration: const BoxDecoration(
          color: BrandColors.background,
          border: Border(top: BorderSide(color: BrandColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _circleIcon(Icons.add, BrandColors.surface, BrandColors.foreground,
                onTap: canSend ? () {} : null),
            const SizedBox(width: Spacing.x2),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: BrandColors.surface,
                  borderRadius: BorderRadius.circular(Radii.pill),
                  border: Border.all(color: BrandColors.border),
                ),
                padding: const EdgeInsets.only(left: Spacing.x4, right: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        enabled: canSend,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        style:
                            const TextStyle(color: BrandColors.foreground),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          hintText: canSend
                              ? 'Message…'
                              : 'Read-only conversation',
                          hintStyle:
                              const TextStyle(color: BrandColors.mutedFg),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                        onSubmitted: (_) =>
                            canSend && !_sending ? _send() : null,
                      ),
                    ),
                    const Icon(Icons.emoji_emotions_outlined,
                        color: BrandColors.mutedFg, size: 22),
                  ],
                ),
              ),
            ),
            const SizedBox(width: Spacing.x2),
            _sendOrMic(canSend),
          ],
        ),
      ),
    );
  }

  Widget _sendOrMic(bool canSend) {
    final showSend = _hasText;
    return InkWell(
      onTap: canSend && !_sending && showSend ? _send : null,
      customBorder: const CircleBorder(),
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: BrandColors.primary,
          shape: BoxShape.circle,
        ),
        child: _sending
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: BrandColors.primaryFg),
              )
            : Icon(
                showSend ? Icons.send : Icons.mic,
                color: BrandColors.primaryFg,
                size: 22,
              ),
      ),
    );
  }

  Widget _circleIcon(IconData icon, Color bg, Color fg,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: BrandColors.border),
        ),
        child: Icon(icon, color: fg, size: 22),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? BrandColors.primary : BrandColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          border: isMine
              ? null
              : Border.all(color: BrandColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMine ? BrandColors.primaryFg : BrandColors.foreground,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.createdAt != null)
                  Text(
                    Formatters.time(message.createdAt!),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMine
                          ? BrandColors.primaryFg.withValues(alpha: 0.7)
                          : BrandColors.mutedFg,
                    ),
                  ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 13,
                    color: message.isRead
                        ? BrandColors.primaryFg
                        : BrandColors.primaryFg.withValues(alpha: 0.5),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
