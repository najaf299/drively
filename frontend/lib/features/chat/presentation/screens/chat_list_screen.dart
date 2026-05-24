import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/chat.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/providers/chat_provider.dart';

/// Conversation list (Messages tab) — spec tokens.
/// Unread: primary dot/badge. Rows on surface. Swipe a row to archive (→) or
/// delete (←); both offer an Undo.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(threadsProvider);
    final me = ref.watch(currentUserIdProvider) ?? '';
    final listState = ref.watch(chatListControllerProvider);
    final controller = ref.read(chatListControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x4),
              child: Row(
                children: [
                  Text(
                    listState.showArchived ? 'Archived' : 'Messages',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const Spacer(),
                  if (listState.archived.isNotEmpty)
                    _ArchivedToggle(
                      showingArchived: listState.showArchived,
                      count: listState.archived.length,
                      onTap: controller.toggleShowArchived,
                    ),
                ],
              ),
            ),
            Expanded(
              child: AsyncValueView<List<ChatThread>>(
                value: threads,
                onRetry: () => ref.invalidate(threadsProvider),
                data: (list) {
                  // Apply client-side archive/delete filtering.
                  final visible = list.where((t) {
                    if (listState.deleted.contains(t.id)) return false;
                    final isArchived = listState.archived.contains(t.id);
                    return listState.showArchived ? isArchived : !isArchived;
                  }).toList();

                  if (visible.isEmpty) {
                    return EmptyView(
                      icon: listState.showArchived
                          ? Icons.archive_outlined
                          : Icons.forum_outlined,
                      title: listState.showArchived
                          ? 'No archived chats'
                          : 'No messages yet',
                      subtitle: listState.showArchived
                          ? 'Chats you archive will appear here.'
                          : 'Conversations with hosts and renters appear here.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(threadsProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                          Spacing.x5, 0, Spacing.x5, Spacing.x5),
                      itemCount: visible.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: Spacing.x3),
                      itemBuilder: (_, i) {
                        final thread = visible[i];
                        return _SwipeableThread(
                          key: ValueKey(thread.id),
                          thread: thread,
                          me: me,
                          archived: listState.showArchived,
                          controller: controller,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps a thread tile in a [Dismissible]: swipe right = archive/unarchive,
/// swipe left = delete. Each action shows an Undo snackbar.
class _SwipeableThread extends StatelessWidget {
  final ChatThread thread;
  final String me;
  final bool archived;
  final ChatListController controller;

  const _SwipeableThread({
    super.key,
    required this.thread,
    required this.me,
    required this.archived,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss-${thread.id}'),
      // Right swipe (startToEnd) → archive/unarchive.
      background: _SwipeBg(
        alignment: Alignment.centerLeft,
        color: BrandColors.warning,
        icon: archived ? Icons.unarchive_outlined : Icons.archive_outlined,
        label: archived ? 'Unarchive' : 'Archive',
      ),
      // Left swipe (endToStart) → delete.
      secondaryBackground: const _SwipeBg(
        alignment: Alignment.centerRight,
        color: BrandColors.destructive,
        icon: Icons.delete_outline,
        label: 'Delete',
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          if (archived) {
            controller.unarchive(thread.id);
            _toast(context, 'Chat unarchived.');
          } else {
            controller.archive(thread.id);
            _toast(context, 'Chat archived.');
          }
        } else {
          controller.delete(thread.id);
          _toast(context, 'Chat deleted.');
        }
      },
      child: _ThreadTile(thread: thread, me: me),
    );
  }

  void _toast(BuildContext context, String message) {
    AppSnack.show(
      context,
      message,
      type: SnackType.info,
      actionLabel: 'Undo',
      onAction: () => controller.restore(thread.id),
    );
  }
}

/// The coloured background revealed while swiping a thread.
class _SwipeBg extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  const _SwipeBg({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final left = alignment == Alignment.centerLeft;
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.x5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (left) ...[
            Icon(icon, color: color),
            const SizedBox(width: Spacing.x2),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: color)),
          ] else ...[
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: color)),
            const SizedBox(width: Spacing.x2),
            Icon(icon, color: color),
          ],
        ],
      ),
    );
  }
}

/// Small pill toggling between the active list and the archived list.
class _ArchivedToggle extends StatelessWidget {
  final bool showingArchived;
  final int count;
  final VoidCallback onTap;

  const _ArchivedToggle({
    required this.showingArchived,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.x3, vertical: Spacing.x2),
        decoration: BoxDecoration(
          color: BrandColors.surface2,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: BrandColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(showingArchived ? Icons.inbox_outlined : Icons.archive_outlined,
                size: Sizes.iconSm, color: BrandColors.foreground),
            const SizedBox(width: Spacing.x2),
            Text(
              showingArchived ? 'Inbox' : 'Archived ($count)',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: BrandColors.foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final ChatThread thread;
  final String me;
  const _ThreadTile({required this.thread, required this.me});

  @override
  Widget build(BuildContext context) {
    final other = thread.otherParticipant(me);
    final last = thread.latestMessage;
    final name = other?.name ?? 'Conversation';
    final unread = thread.hasUnread;

    return Material(
      color: BrandColors.surface,
      borderRadius: BorderRadius.circular(Radii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.card),
        onTap: () => context.push(
          '/chat/${thread.id}',
          extra: {
            'recipientId': other?.id,
            'name': other?.name,
            'bookingId': thread.bookingId,
          },
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.x3),
          child: Row(
            children: [
              // AppAvatar — surface2 bg, no coral.
              AppAvatar(
                initials: other?.initials ?? '?',
                radius: 24,
              ),
              const SizedBox(width: Spacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: unread
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      last?.content ?? 'Tap to chat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: unread
                                ? BrandColors.foreground
                                : BrandColors.mutedFg,
                            fontWeight: unread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.x2),
              // Timestamp + unread primary dot
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (last?.createdAt != null)
                    Text(
                      Formatters.timeAgo(last!.createdAt!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 6),
                  if (unread)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: BrandColors.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(height: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
