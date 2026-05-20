import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/chat.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_avatar.dart';
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
      appBar: AppBar(
        title: const Text('Messages'),
        automaticallyImplyLeading: false,
      ),
      body: AsyncValueView<List<ChatThread>>(
        value: threads,
        onRetry: () => ref.invalidate(threadsProvider),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyView(
              icon: Icons.forum_outlined,
              title: 'No messages yet',
              subtitle: 'Conversations with hosts and renters appear here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(threadsProvider),
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: BrandColors.border),
              itemBuilder: (_, i) {
                final thread = list[i];
                final other = thread.otherParticipant(me);
                final last = thread.latestMessage;
                return ListTile(
                  onTap: () => context.push(
                    '/chat/${thread.id}',
                    extra: {
                      'recipientId': other?.id,
                      'name': other?.name,
                      'bookingId': thread.bookingId,
                    },
                  ),
                  leading: AppAvatar(
                    imageUrl: other?.avatarUrl,
                    initials: other?.initials ?? '?',
                    radius: 24,
                  ),
                  title: Text(other?.name ?? 'Conversation',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    last?.content ?? 'Tap to chat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: BrandColors.mutedFg),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (last?.createdAt != null)
                        Text(Formatters.timeAgo(last!.createdAt!),
                            style: const TextStyle(
                                color: BrandColors.mutedFg, fontSize: 11)),
                      if (thread.hasUnread) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: BrandColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text('${thread.unreadCount}',
                              style: const TextStyle(
                                  color: BrandColors.primaryFg,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
