import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/booking.dart';
import '../../../../core/models/car.dart';
import '../../../../core/models/earning.dart';
import '../../../../core/models/host_verification.dart';
import '../../data/host_service.dart';

/// Host onboarding/verification state.
final hostVerificationProvider =
    FutureProvider.autoDispose<HostVerification>((ref) {
  return ref.watch(hostServiceProvider).verificationStatus();
});

/// Aggregate host dashboard stats (shape varies; consumed defensively).
final hostStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(hostServiceProvider).stats();
});

/// The host's fleet.
final hostCarsProvider = FutureProvider.autoDispose<List<Car>>((ref) async {
  final result = await ref.watch(hostServiceProvider).cars();
  return result.items;
});

/// Bookings across the host's fleet (grouped client-side by status).
final hostBookingsProvider =
    FutureProvider.autoDispose<List<Booking>>((ref) async {
  final result = await ref.watch(hostServiceProvider).bookings();
  return result.items;
});

/// Earnings summary for the given period (week | month | year).
final hostEarningsProvider =
    FutureProvider.family<EarningsSummary, String>((ref, period) {
  return ref.watch(hostServiceProvider).earnings(period: period);
});

/// Per-booking earning history.
final hostEarningsHistoryProvider =
    FutureProvider.autoDispose<List<Earning>>((ref) async {
  final result = await ref.watch(hostServiceProvider).earningsHistory();
  return result.items;
});
