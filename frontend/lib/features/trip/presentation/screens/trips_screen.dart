import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/booking.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/trip_card.dart';
import '../../../booking/domain/providers/booking_provider.dart';

/// "My Trips" with Upcoming / Ongoing / Past tabs.
class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Trips'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            indicatorColor: BrandColors.primary,
            labelColor: BrandColors.primary,
            unselectedLabelColor: BrandColors.mutedFg,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Ongoing'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: AsyncValueView<List<Booking>>(
          value: bookings,
          onRetry: () => ref.invalidate(bookingsProvider),
          data: (list) {
            final upcoming =
                list.where((b) => b.isPending || b.isConfirmed).toList();
            final ongoing = list.where((b) => b.isActive).toList();
            final past =
                list.where((b) => b.isCompleted || b.isCancelled).toList();

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(bookingsProvider),
              child: TabBarView(
                children: [
                  _list(context, upcoming, 'No upcoming trips',
                      'Browse cars and book your next drive.'),
                  _list(context, ongoing, 'No active trips',
                      'Your ongoing trips will appear here.'),
                  _list(context, past, 'No past trips',
                      'Completed trips show up here.'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    List<Booking> items,
    String emptyTitle,
    String emptySubtitle,
  ) {
    if (items.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          EmptyView(
            icon: Icons.luggage_outlined,
            title: emptyTitle,
            subtitle: emptySubtitle,
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(Spacing.x5),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: Spacing.x3),
      itemBuilder: (_, i) => TripCard(
        booking: items[i],
        onTap: () => context.push('/bookings/${items[i].id}'),
      ),
    );
  }
}
