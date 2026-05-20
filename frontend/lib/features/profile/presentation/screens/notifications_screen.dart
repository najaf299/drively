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

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _filter = 'all';

  static (IconData, Color) _style(String category) {
    return switch (category) {
      'booking' => (Icons.event_available, BrandColors.primary),
      'payment' => (Icons.account_balance_wallet, BrandColors.success),
      'alert' => (Icons.warning_amber_rounded, BrandColors.warning),
      'promo' => (Icons.local_offer, BrandColors.accent),
      'message' => (Icons.chat_bubble_outline, BrandColors.accent),
      _ => (Icons.notifications_none, BrandColors.mutedFg),
    };
  }

  bool _matches(AppNotification n) {
    switch (_filter) {
      case 'trips':
        return n.category == 'booking' || n.category == 'alert';
      case 'messages':
        return n.category == 'message';
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifs = ref.watch(notificationsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.x5, Spacing.x4, Spacing.x5, 0),
              child: Row(
                children: [
                  Text('Notifications',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(notificationServiceProvider)
                          .markAllRead();
                      ref.invalidate(notificationsProvider);
                    },
                    child: const Text('Mark all read'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.x3),
            _filterPills(notifs.valueOrNull ?? const []),
            const SizedBox(height: Spacing.x3),
            Expanded(
              child: AsyncValueView<List<AppNotification>>(
                value: notifs,
                onRetry: () => ref.invalidate(notificationsProvider),
                data: (all) {
                  final list = all.where(_matches).toList();
                  if (list.isEmpty) {
                    return const _EmptyNotifications();
                  }
                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(notificationsProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                          Spacing.x5, 0, Spacing.x5, Spacing.x6),
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: Spacing.x3),
                      itemBuilder: (_, i) => _tile(list[i]),
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

  Widget _filterPills(List<AppNotification> all) {
    final pills = <(String, String)>[
      ('all', 'All · ${all.length}'),
      ('trips', 'Trips'),
      ('messages', 'Messages'),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.x5),
        itemCount: pills.length,
        separatorBuilder: (_, __) => const SizedBox(width: Spacing.x2),
        itemBuilder: (_, i) {
          final (key, label) = pills[i];
          final selected = key == _filter;
          return GestureDetector(
            onTap: () => setState(() => _filter = key),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.x4, vertical: Spacing.x2),
              decoration: BoxDecoration(
                color: selected ? BrandColors.primary : BrandColors.surface,
                borderRadius: BorderRadius.circular(Radii.pill),
                border: Border.all(
                    color:
                        selected ? BrandColors.primary : BrandColors.border),
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: selected
                          ? BrandColors.primaryFg
                          : BrandColors.foreground,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tile(AppNotification n) {
    final (icon, color) = _style(n.category);
    return Material(
      color: BrandColors.surface,
      borderRadius: BorderRadius.circular(Radii.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.xl),
        onTap: () async {
          final router = GoRouter.of(context);
          if (!n.isRead) {
            await ref.read(notificationServiceProvider).markRead(n.id);
            ref.invalidate(notificationsProvider);
          }
          final link = n.deepLink;
          if (link != null && mounted) {
            unawaited(router.push(link));
          }
        },
        child: Container(
          padding: const EdgeInsets.all(Spacing.x3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.xl),
            border: Border.all(color: BrandColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: Spacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (n.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(n.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Spacing.x2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (n.createdAt != null)
                    Text(Formatters.timeAgo(n.createdAt!),
                        style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: Spacing.x2),
                  if (!n.isRead)
                    Container(
                      width: 8,
                      height: 8,
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

/// "All caught up" empty state: a lime bell chip and a [headlineSmall] title.
class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: BrandColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active_outlined,
                  size: 44, color: BrandColors.primary),
            ),
            const SizedBox(height: Spacing.x5),
            Text('All caught up',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: Spacing.x2),
            Text(
              'We\'ll let you know about bookings, trips and more.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BrandColors.mutedFg,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
