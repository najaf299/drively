import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/chat.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/providers/chat_provider.dart';

/// Conversation list (used as the Messages tab for both renters and hosts).
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(threadsProvider);
    final me = ref.watch(currentUserIdProvider) ?? '';

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x4),
              child: Text('Messages',
                  style: Theme.of(context).textTheme.displaySmall),
            ),
            Expanded(
              child: AsyncValueView<List<ChatThread>>(
                value: threads,
                onRetry: () => ref.invalidate(threadsProvider),
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyView(
                      icon: Icons.forum_outlined,
                      title: 'No messages yet',
                      subtitle:
                          'Conversations with hosts and renters appear here.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(threadsProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                          Spacing.x5, 0, Spacing.x5, Spacing.x5),
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: Spacing.x3),
                      itemBuilder: (_, i) =>
                          _ThreadTile(thread: list[i], me: me),
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

class _ThreadTile extends StatelessWidget {
  final ChatThread thread;
  final String me;
  const _ThreadTile({required this.thread, required this.me});

  @override
  Widget build(BuildContext context) {
    final other = thread.otherParticipant(me);
    final last = thread.latestMessage;
    final name = other?.name ?? 'Conversation';

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
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: BrandColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  other?.initials ?? '?',
                  style: const TextStyle(
                    color: BrandColors.primaryFg,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      last?.content ?? 'Tap to chat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: thread.hasUnread
                                ? BrandColors.foreground
                                : BrandColors.mutedFg,
                            fontWeight: thread.hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.x2),
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
                  if (thread.hasUnread)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: BrandColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
