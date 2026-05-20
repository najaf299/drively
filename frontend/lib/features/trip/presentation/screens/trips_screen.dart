import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/booking.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/trip_card.dart';
import '../../../booking/domain/providers/booking_provider.dart';

/// "Trips" with Upcoming / Active / Past segmented pills.
class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  int _tab = 0;

  static const _tabs = ['Upcoming', 'Active', 'Past'];

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(bookingsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                  Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x4),
              child: Text(
                'Trips',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: BrandColors.foreground,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.x5),
              child: _segments(),
            ),
            const SizedBox(height: Spacing.x4),
            Expanded(
              child: AsyncValueView<List<Booking>>(
                value: bookings,
                onRetry: () => ref.invalidate(bookingsProvider),
                data: (list) {
                  final upcoming =
                      list.where((b) => b.isPending || b.isConfirmed).toList();
                  final active = list.where((b) => b.isActive).toList();
                  final past = list
                      .where((b) => b.isCompleted || b.isCancelled)
                      .toList();

                  final current = switch (_tab) {
                    0 => upcoming,
                    1 => active,
                    _ => past,
                  };
                  final emptyTitle = switch (_tab) {
                    0 => 'No upcoming trips',
                    1 => 'No active trips',
                    _ => 'No past trips',
                  };
                  final emptySubtitle = switch (_tab) {
                    0 => 'Browse cars and book your next drive.',
                    1 => 'Your ongoing trips will appear here.',
                    _ => 'Completed trips show up here.',
                  };

                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(bookingsProvider),
                    child: _list(current, emptyTitle, emptySubtitle),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segments() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = _tab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      selected ? BrandColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Text(
                  _tabs[i],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: selected
                        ? BrandColors.primaryFg
                        : BrandColors.mutedFg,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _list(
    List<Booking> items,
    String emptyTitle,
    String emptySubtitle,
  ) {
    if (items.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          EmptyView(
            icon: Icons.luggage_outlined,
            title: emptyTitle,
            subtitle: emptySubtitle,
          ),
        ],
      );
    }

    // On the Upcoming tab, present the soonest trip as a featured hero.
    final featureFirst = _tab == 0 && items.isNotEmpty;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          Spacing.x5, 0, Spacing.x5, Spacing.x5),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: Spacing.x3),
      itemBuilder: (_, i) => TripCard(
        booking: items[i],
        featured: featureFirst && i == 0,
        onTap: () => context.push('/bookings/${items[i].id}'),
      ),
    );
  }
}
