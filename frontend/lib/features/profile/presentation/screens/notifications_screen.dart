import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/notification.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../data/notification_service.dart';
import '../../domain/providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static (IconData, Color) _style(String category) {
    return switch (category) {
      'booking' => (Icons.event_available, BrandColors.primary),
      'payment' => (Icons.account_balance_wallet, BrandColors.success),
      'alert' => (Icons.warning_amber_rounded, BrandColors.warning),
      'promo' => (Icons.local_offer, BrandColors.accent),
      'message' => (Icons.chat_bubble_outline, BrandColors.primary),
      _ => (Icons.notifications_none, BrandColors.mutedFg),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all read',
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await ref.read(notificationServiceProvider).markAllRead();
              ref.invalidate(notificationsProvider);
            },
          ),
        ],
      ),
      body: AsyncValueView<List<AppNotification>>(
        value: notifs,
        onRetry: () => ref.invalidate(notificationsProvider),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyView(
              icon: Icons.notifications_none,
              title: 'All caught up!',
              subtitle: 'We\'ll let you know about bookings, trips and more.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: BrandColors.border),
              itemBuilder: (_, i) {
                final n = list[i];
                final (icon, color) = _style(n.category);
                return ListTile(
                  tileColor: n.isRead ? null : BrandColors.surface,
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  title: Text(n.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: n.body.isEmpty
                      ? null
                      : Text(n.body,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: n.createdAt != null
                      ? Text(Formatters.timeAgo(n.createdAt!),
                          style: const TextStyle(
                              color: BrandColors.mutedFg, fontSize: 11))
                      : null,
                  onTap: () async {
                    if (!n.isRead) {
                      await ref
                          .read(notificationServiceProvider)
                          .markRead(n.id);
                      ref.invalidate(notificationsProvider);
                    }
                    final link = n.deepLink;
                    if (link != null && context.mounted) {
                      unawaited(context.push(link));
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
