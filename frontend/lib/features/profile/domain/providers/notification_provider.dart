import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/notification.dart';
import '../../data/notification_service.dart';

/// In-app notification inbox (first page).
final notificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final result = await ref.watch(notificationServiceProvider).list();
  return result.items;
});

/// Count of unread notifications (drives the bell badge).
final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final notifs = ref.watch(notificationsProvider).valueOrNull ?? const [];
  return notifs.where((n) => !n.isRead).length;
});
