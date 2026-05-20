import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/booking.dart';
import '../../data/booking_service.dart';

/// All of the current customer's bookings (newest first). Screens group these
/// into Upcoming / Ongoing / Past tabs client-side.
final bookingsProvider = FutureProvider.autoDispose<List<Booking>>((ref) async {
  final result = await ref.watch(bookingServiceProvider).list();
  return result.items;
});

/// A single booking with full detail (car, host, payment, trip, reviews).
final bookingDetailProvider = FutureProvider.family<Booking, String>((ref, id) {
  return ref.watch(bookingServiceProvider).get(id);
});
