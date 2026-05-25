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

/// Notifications screen — spec §3.2 / §7.20.
///
/// Filter tabs: All · Unread · Trips · Payments · Promos.
/// Each row 88h — 44 round icon with tonal bg by channel:
///   bookings = primary, payments = success, promo = accent (purple),
///   system = info, message = info.
/// Unread rows: 8px primary dot + surface2 bg. Read rows: surface bg.
/// Empty state: primary bell icon + headlineSmall "You're all caught up".
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _filter = 'all';

  // Spec §3.2 channel → (icon, color):
  // bookings=primary, payments=success, promo=accent(purple),
  // system=info, message=info
  static (IconData, Color) _channelStyle(String category) {
    return switch (category) {
      'booking' => (Icons.event_available_outlined, BrandColors.primary),
      'payment' => (Icons.account_balance_wallet_outlined, BrandColors.success),
      'promo' => (Icons.local_offer_outlined, BrandColors.accent),
      'system' => (Icons.info_outline, BrandColors.info),
      'message' => (Icons.chat_bubble_outline, BrandColors.info),
      'alert' => (Icons.warning_amber_rounded, BrandColors.warning),
      _ => (Icons.notifications_none, BrandColors.mutedFg),
    };
  }

  bool _matches(AppNotification n) {
    switch (_filter) {
      case 'unread':
        return !n.isRead;
      case 'trips':
        return n.category == 'booking' || n.category == 'alert';
      case 'payments':
        return n.category == 'payment';
      case 'promos':
        return n.category == 'promo';
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
            // Filter tabs: All · Unread · Trips · Payments · Promos
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
                          const SizedBox(height: Spacing.x2),
                      itemBuilder: (_, i) => _NotifTile(
                        n: list[i],
                        onTap: () async {
                          final router = GoRouter.of(context);
                          if (!list[i].isRead) {
                            await ref
                                .read(notificationServiceProvider)
                                .markRead(list[i].id);
                            ref.invalidate(notificationsProvider);
                          }
                          final link = list[i].deepLink;
                          if (link != null && mounted) {
                            unawaited(router.push(link));
                          }
                        },
                      ),
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
    final unreadCount = all.where((n) => !n.isRead).length;
    final pills = <(String, String)>[
      ('all', 'All · ${all.length}'),
      ('unread', 'Unread${unreadCount > 0 ? ' · $unreadCount' : ''}'),
      ('trips', 'Trips'),
      ('payments', 'Payments'),
      ('promos', 'Promos'),
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.x4, vertical: Spacing.x2),
              decoration: BoxDecoration(
                color: selected ? BrandColors.primary : BrandColors.surface,
                borderRadius: BorderRadius.circular(Radii.pill),
                border: Border.all(
                    color: selected
                        ? BrandColors.primary
                        : BrandColors.border),
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
}

// ─── Notification row (88h) ───────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onTap;
  const _NotifTile({required this.n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, color) =
        _NotificationsScreenState._channelStyle(n.category);
    // Unread rows: surface2 bg + primary dot. Read: surface bg.
    final rowBg = n.isRead ? BrandColors.surface : BrandColors.surface2;

    return Material(
      color: rowBg,
      borderRadius: BorderRadius.circular(Radii.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.xl),
        onTap: onTap,
        child: Container(
          // 88h per spec
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(Spacing.x3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.xl),
            border: Border.all(color: BrandColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 44 round icon with tonal bg
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: Sizes.icon),
              ),
              const SizedBox(width: Spacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // title 14 w600 (1 line)
                    Text(
                      n.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (n.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      // body 13 muted (2 lines)
                      Text(
                        n.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 13,
                                  color: BrandColors.mutedFg,
                                ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Spacing.x2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (n.createdAt != null)
                    Text(Formatters.timeAgo(n.createdAt!),
                        style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: Spacing.x2),
                  // Unread: 8px primary dot
                  if (!n.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
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

// ─── Empty state ──────────────────────────────────────────────────────────────

/// "You're all caught up": primary bell icon + headlineSmall.
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
              child: Icon(Icons.notifications_active_outlined,
                  size: 44, color: BrandColors.primary),
            ),
            const SizedBox(height: Spacing.x5),
            Text("You're all caught up",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: Spacing.x2),
            Text(
              "We'll let you know about bookings, trips and more.",
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
