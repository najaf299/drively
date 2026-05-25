import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/chat.dart';
import '../../../../core/network/realtime_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/chat_service.dart';
import '../../domain/providers/chat_provider.dart';

/// 1:1 chat — spec §7.19.
///
/// Outgoing bubbles: primary bg, primaryFg text, radius 18, bottom-right = 4.
/// Incoming: surface2. Timestamps bodySmall muted below.
/// System pill: surface2 @60. Composer on surface; send = 40 round primary.
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
  final _inputFocus = FocusNode();
  final _scroll = ScrollController();
  StreamSubscription<RealtimeEvent>? _rt;
  bool _sending = false;
  bool _hasText = false;
  bool _emojiOpen = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(() {
      final has = _input.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    // Tapping into the field (raising the keyboard) closes the emoji panel.
    _inputFocus.addListener(() {
      if (_inputFocus.hasFocus && _emojiOpen) {
        setState(() => _emojiOpen = false);
      }
    });
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
    _inputFocus.dispose();
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
          bottom: false,
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: AsyncValueView<List<ChatMessage>>(
                    value: messages,
                    onRetry: () => ref
                        .read(chatMessagesProvider(widget.threadId).notifier)
                        .load(),
                    data: (list) {
                      if (list.isEmpty) {
                        return const EmptyView(
                          icon: Icons.waving_hand_outlined,
                          title: 'Say hi!',
                          subtitle: 'Start the conversation.',
                        );
                      }
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => _scrollToBottom());
                      return ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(
                            Spacing.x4, Spacing.x3, Spacing.x4, Spacing.x3),
                        itemCount: list.length + 1,
                        itemBuilder: (_, i) {
                          if (i == 0) return _dateSeparator(context, list);
                          final m = list[i - 1];
                          return _Bubble(message: m, isMine: m.isFromMe(me));
                        },
                      );
                    },
                  ),
                ),
              ),
              _composerBar(context),
              // Emoji panel takes the keyboard's place; otherwise reserve the
              // home-indicator inset (which collapses to 0 when typing).
              if (_emojiOpen)
                _EmojiPicker(
                  onSelect: _insertEmoji,
                  onBackspace: _backspace,
                )
              else
                SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final name = widget.recipientName ?? 'Chat';
    return Container(
      padding: const EdgeInsets.fromLTRB(
          Spacing.x4, Spacing.x2, Spacing.x4, Spacing.x2),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.canPop() ? context.pop() : context.go('/'),
            customBorder: const CircleBorder(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BrandColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back,
                  size: 20, color: BrandColors.foreground),
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
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: BrandColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Online',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: BrandColors.success),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.call_outlined, color: BrandColors.primary),
          ),
        ],
      ),
    );
  }

  /// System date separator — surface2 @60 center pill.
  Widget _dateSeparator(BuildContext context, List<ChatMessage> list) {
    final ts = list.isNotEmpty ? list.first.createdAt : null;
    final label = ts != null ? 'TODAY  ·  ${Formatters.time(ts)}' : 'TODAY';
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: Spacing.x3),
        padding:
            const EdgeInsets.symmetric(horizontal: Spacing.x3, vertical: 5),
        decoration: BoxDecoration(
          color: BrandColors.surface2.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 0.4,
              ),
        ),
      ),
    );
  }

  /// Composer bar — attachment · pill input with emoji toggle · send/mic.
  Widget _composerBar(BuildContext context) {
    final canSend = widget.recipientId != null;
    return Container(
      decoration: BoxDecoration(
        color: BrandColors.surface,
        // Curved top edge matching the app's rounded aesthetic.
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xxl)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Spacing.x3, Spacing.x2, Spacing.x3, Spacing.x2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attachment — opens the share sheet.
            _circleIcon(Icons.add, BrandColors.surface2, BrandColors.foreground,
                onTap: canSend ? () => _openAttachments(context) : null),
            const SizedBox(width: Spacing.x2),
            // Pill input + emoji/keyboard toggle.
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 38),
                decoration: BoxDecoration(
                  color: BrandColors.surface2,
                  borderRadius: BorderRadius.circular(Radii.pill),
                  border: Border.all(color: BrandColors.border),
                ),
                padding: const EdgeInsets.only(left: Spacing.x4, right: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: TextField(
                          controller: _input,
                          focusNode: _inputFocus,
                          enabled: canSend,
                          minLines: 1,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: BrandColors.foreground),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            hintText:
                                canSend ? 'Message…' : 'Read-only conversation',
                            hintStyle: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: BrandColors.subtleFg),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                          onSubmitted: (_) =>
                              canSend && !_sending ? _send() : null,
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: canSend ? _toggleEmoji : null,
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(
                          _emojiOpen
                              ? Icons.keyboard_rounded
                              : Icons.emoji_emotions_outlined,
                          color: _emojiOpen
                              ? BrandColors.primary
                              : BrandColors.mutedFg,
                          size: Sizes.icon,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: Spacing.x2),
            _sendButton(canSend),
          ],
        ),
      ),
    );
  }

  /// Swap the keyboard for the emoji panel (and back).
  void _toggleEmoji() {
    if (_emojiOpen) {
      setState(() => _emojiOpen = false);
      _inputFocus.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
      setState(() => _emojiOpen = true);
      _scrollToBottom();
    }
  }

  /// Insert an emoji at the caret (replacing any selection).
  void _insertEmoji(String emoji) {
    final text = _input.text;
    final sel = _input.selection;
    final start = sel.start < 0 ? text.length : sel.start;
    final end = sel.end < 0 ? text.length : sel.end;
    final next = text.replaceRange(start, end, emoji);
    _input.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  /// Delete one grapheme from the end so multi-codepoint emoji clear cleanly.
  void _backspace() {
    final text = _input.text;
    if (text.isEmpty) return;
    final next = text.characters.skipLast(1).toString();
    _input.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  Future<void> _openAttachments(BuildContext context) async {
    FocusScope.of(context).unfocus();
    if (_emojiOpen) setState(() => _emojiOpen = false);
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: BrandColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xxl)),
      ),
      builder: (_) => _AttachmentSheet(
        onPick: (label) {
          Navigator.pop(context);
          AppSnack.show(context, '$label sharing is coming soon.',
              type: SnackType.info);
        },
      ),
    );
  }

  Widget _sendButton(bool canSend) {
    final hasText = _hasText && !_sending;
    final bg = canSend && hasText ? BrandColors.primary : BrandColors.surface2;
    final fg = !canSend
        ? BrandColors.mutedFg
        : (hasText ? BrandColors.primaryFg : BrandColors.foreground);
    VoidCallback? onTap;
    if (canSend && !_sending) {
      onTap = hasText
          ? _send
          : () => AppSnack.show(context, 'Voice messages are coming soon.',
              type: SnackType.info);
    }
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: _sending
            ? Padding(
                padding: EdgeInsets.all(11),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: BrandColors.mutedFg),
              )
            : Icon(
                hasText ? Icons.send_rounded : Icons.mic_none_rounded,
                color: fg,
                size: 20,
              ),
      ),
    );
  }

  Widget _circleIcon(IconData icon, Color bg, Color fg, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: BrandColors.border),
        ),
        child: Icon(icon, color: fg, size: Sizes.iconSm),
      ),
    );
  }
}

/// Inline emoji panel that takes the keyboard's place. Tapping an emoji inserts
/// it at the caret; the backspace pill deletes a trailing grapheme.
class _EmojiPicker extends StatelessWidget {
  final ValueChanged<String> onSelect;
  final VoidCallback onBackspace;
  const _EmojiPicker({required this.onSelect, required this.onBackspace});

  static const _emojis = <String>[
    '😀',
    '😁',
    '😂',
    '🤣',
    '😊',
    '😍',
    '😘',
    '😎',
    '🤩',
    '🥳',
    '😇',
    '🙂',
    '😉',
    '😌',
    '😋',
    '😜',
    '🤔',
    '🤗',
    '🫡',
    '😴',
    '😢',
    '😭',
    '😅',
    '🙄',
    '😏',
    '😮',
    '🤯',
    '🥹',
    '😤',
    '🤷',
    '👍',
    '👎',
    '👏',
    '🙌',
    '🙏',
    '👌',
    '✌️',
    '🤝',
    '💪',
    '👋',
    '❤️',
    '🧡',
    '💛',
    '💚',
    '💙',
    '💜',
    '🖤',
    '🤍',
    '💯',
    '🔥',
    '✨',
    '⭐',
    '🎉',
    '✅',
    '❌',
    '💰',
    '💳',
    '📍',
    '🗺️',
    '🧭',
    '🚗',
    '🚕',
    '🚙',
    '🏎️',
    '⛽',
    '🅿️',
    '🚦',
    '🔑',
    '👀',
    '🤙',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: BrandColors.surface,
        border: Border(top: BorderSide(color: BrandColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.x3, Spacing.x3, Spacing.x3, 0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                itemCount: _emojis.length,
                itemBuilder: (_, i) => InkWell(
                  borderRadius: BorderRadius.circular(Radii.md),
                  onTap: () => onSelect(_emojis[i]),
                  child: Center(
                    child:
                        Text(_emojis[i], style: const TextStyle(fontSize: 24)),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.x4, vertical: Spacing.x2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(Radii.pill),
                  onTap: onBackspace,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.x4, vertical: Spacing.x2),
                    decoration: BoxDecoration(
                      color: BrandColors.surface2,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                    child: Icon(Icons.backspace_outlined,
                        size: Sizes.iconSm, color: BrandColors.foreground),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Share sheet shown by the composer's "+" — a row of attachment options.
class _AttachmentSheet extends StatelessWidget {
  final ValueChanged<String> onPick;
  const _AttachmentSheet({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, Color)>[
      (Icons.photo_library_outlined, 'Photos', BrandColors.primary),
      (Icons.photo_camera_outlined, 'Camera', BrandColors.info),
      (Icons.description_outlined, 'Document', BrandColors.warning),
      (Icons.location_on_outlined, 'Location', BrandColors.success),
    ];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Spacing.x5, Spacing.x3, Spacing.x5, Spacing.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: Spacing.x4),
                decoration: BoxDecoration(
                  color: BrandColors.borderStrong,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
              ),
            ),
            Text('Share', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Spacing.x5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final (icon, label, color) in items)
                  _AttachOption(
                    icon: icon,
                    label: label,
                    color: color,
                    onTap: () => onPick(label),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: Sizes.iconLg),
          ),
          const SizedBox(height: Spacing.x2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Chat bubble — spec §7.19.
/// Outgoing: primary bg, primaryFg text, radius 18, bottom-right corner 4.
/// Incoming: surface2 bg, foreground text, bottom-left corner 4.
class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  const _Bubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    const r = 18.0;
    const corner = 4.0;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding:
            const EdgeInsets.symmetric(horizontal: Spacing.x4, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? BrandColors.primary : BrandColors.surface2,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(r),
            topRight: const Radius.circular(r),
            bottomLeft: Radius.circular(isMine ? r : corner),
            bottomRight: Radius.circular(isMine ? corner : r),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color:
                        isMine ? BrandColors.primaryFg : BrandColors.foreground,
                  ),
            ),
            const SizedBox(height: 3),
            // Timestamp + read receipt — bodySmall muted, grouped below.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.createdAt != null)
                  Text(
                    Formatters.time(message.createdAt!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isMine
                              ? BrandColors.primaryFg.withValues(alpha: 0.65)
                              : BrandColors.mutedFg,
                          fontSize: 11,
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
