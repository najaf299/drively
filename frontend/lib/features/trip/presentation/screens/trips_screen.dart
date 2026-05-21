import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/booking.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/trip_card.dart';
import '../../../booking/domain/providers/booking_provider.dart';

/// "Trips" tab — Upcoming · Active · Past · Cancelled segmented pill tabs.
/// Spec §7.16.
class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  int _tab = 0;

  static const _tabs = ['Upcoming', 'Active', 'Past', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(bookingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x4),
              child: Text('Trips', style: theme.textTheme.displaySmall),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.x5),
              child: _SegmentedTabs(
                tabs: _tabs,
                selected: _tab,
                onSelected: (i) => setState(() => _tab = i),
              ),
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
                  final past = list.where((b) => b.isCompleted).toList();
                  final cancelled = list.where((b) => b.isCancelled).toList();

                  final current = switch (_tab) {
                    0 => upcoming,
                    1 => active,
                    2 => past,
                    _ => cancelled,
                  };

                  const emptyTitles = [
                    'No upcoming trips',
                    'No active trips',
                    'No past trips',
                    'No cancelled trips',
                  ];
                  const emptySubs = [
                    'Browse cars and book your next drive.',
                    'Your ongoing trips will appear here.',
                    'Completed trips show up here.',
                    'Cancelled trips will appear here.',
                  ];

                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(bookingsProvider),
                    child: _list(
                      current,
                      emptyTitles[_tab],
                      emptySubs[_tab],
                      showFindCar: _tab == 0,
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

  /// Status badge mapped per spec v2.
  StatusBadge _badge(Booking b) {
    if (b.isActive) {
      return const StatusBadge('Active', tone: BadgeTone.live, icon: Icons.circle);
    }
    if (b.isCompleted) {
      return const StatusBadge('Completed', tone: BadgeTone.success);
    }
    if (b.isCancelled) {
      return const StatusBadge('Cancelled', tone: BadgeTone.error);
    }
    return const StatusBadge('Upcoming', tone: BadgeTone.neutral);
  }

  Widget _list(
    List<Booking> items,
    String emptyTitle,
    String emptySubtitle, {
    bool showFindCar = false,
  }) {
    if (items.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          EmptyView(
            icon: Icons.luggage_outlined,
            title: emptyTitle,
            subtitle: emptySubtitle,
          ),
          if (showFindCar) ...[
            const SizedBox(height: Spacing.x5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.x10),
              child: FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Find a car'),
              ),
            ),
          ],
        ],
      );
    }

    // On the Upcoming tab present the soonest trip as a featured hero.
    final featureFirst = _tab == 0 && items.isNotEmpty;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          Spacing.x5, 0, Spacing.x5, Spacing.x5),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: Spacing.x3),
      itemBuilder: (_, i) {
        final featured = featureFirst && i == 0;
        return TripCard(
          booking: items[i],
          featured: featured,
          trailing: featured ? null : _badge(items[i]),
          onTap: () => context.push('/bookings/${items[i].id}'),
        );
      },
    );
  }
}

/// Surface-2 capsule segmented tab bar per spec §7.16.
class _SegmentedTabs extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onSelected;

  const _SegmentedTabs({
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BrandColors.surface2,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final sel = selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? BrandColors.surface3 : Colors.transparent,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Text(
                  tabs[i],
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: sel
                        ? BrandColors.foreground
                        : BrandColors.mutedFg,
                    fontWeight:
                        sel ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
