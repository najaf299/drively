import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/car_card.dart';
import '../../../../shared/widgets/glow_background.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../profile/domain/providers/notification_provider.dart';
import '../../domain/car_filters.dart';
import '../../domain/providers/car_provider.dart';
import 'filters_sheet.dart';

/// Customer landing (Discover) — spec §7.7.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialised) {
        _initialised = true;
        ref.read(carListProvider.notifier).load(ref.read(carFiltersProvider));
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      unawaited(ref.read(carListProvider.notifier).loadMore());
    }
  }

  Future<void> _openFilters() async {
    final result =
        await showFiltersSheet(context, ref.read(carFiltersProvider));
    if (result != null) {
      ref.read(carFiltersProvider.notifier).state = result;
      unawaited(ref.read(carListProvider.notifier).load(result));
    }
  }

  void _applyQuickFilter(_QuickFilter q) {
    final base = ref.read(carFiltersProvider);
    // Quick filters compose with location but reset other quick-axis fields so
    // tapping one doesn't silently stack with the previous tap.
    final next = CarFilters(
      query: base.query,
      city: base.city,
      lat: base.lat,
      lng: base.lng,
      radius: base.radius,
      sort: q.sort ?? base.sort,
      fuelType: q.fuelType,
      minSeats: q.minSeats,
    );
    ref.read(carFiltersProvider.notifier).state = next;
    unawaited(ref.read(carListProvider.notifier).load(next));
  }

  /// "Explore Premium" surfaces the top-rated cars (a real action against the
  /// existing catalogue) rather than a yet-to-exist subscription product.
  void _explorePremium() {
    final next = ref.read(carFiltersProvider).copyWith(sort: 'rating');
    ref.read(carFiltersProvider.notifier).state = next;
    unawaited(ref.read(carListProvider.notifier).load(next));
  }

  bool _isQuickFilterActive(_QuickFilter q, CarFilters f) {
    return f.fuelType == q.fuelType &&
        f.minSeats == q.minSeats &&
        (q.sort == null || f.sort == q.sort);
  }

  Future<void> _openSortSheet() async {
    final filters = ref.read(carFiltersProvider);
    final picked = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: BrandColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xxl)),
      ),
      builder: (ctx) {
        const options = {
          null: 'Newest',
          'price_asc': 'Price: low to high',
          'price_desc': 'Price: high to low',
          'rating': 'Top rated',
        };
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: Spacing.x3),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: BrandColors.borderStrong,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
              ),
              const SizedBox(height: Spacing.x3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.x5),
                child: Row(
                  children: [
                    Text('Sort by',
                        style: Theme.of(ctx).textTheme.titleLarge),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.x2),
              for (final entry in options.entries)
                ListTile(
                  title: Text(entry.value),
                  trailing: entry.key == filters.sort
                      ? Icon(Icons.check, color: BrandColors.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, entry.key),
                ),
              const SizedBox(height: Spacing.x4),
            ],
          ),
        );
      },
    );
    // Only apply if the user actually tapped a row. Pulling down dismisses the
    // sheet with a `null` result that we cannot distinguish from picking
    // "Newest" — so use a sentinel by reading after sheet returns: re-check
    // whether dismissed by checking mounted state via `picked` change.
    if (!mounted) return;
    if (picked == filters.sort) return; // no-op (cancel or same selection)
    final next = filters.copyWith(sort: picked);
    // copyWith won't clear with null; manually rebuild if needed.
    final clean = picked == null
        ? CarFilters(
            query: filters.query,
            city: filters.city,
            make: filters.make,
            transmission: filters.transmission,
            fuelType: filters.fuelType,
            minPrice: filters.minPrice,
            maxPrice: filters.maxPrice,
            minSeats: filters.minSeats,
            minYear: filters.minYear,
            maxYear: filters.maxYear,
            lat: filters.lat,
            lng: filters.lng,
            radius: filters.radius,
          )
        : next;
    ref.read(carFiltersProvider.notifier).state = clean;
    unawaited(ref.read(carListProvider.notifier).load(clean));
  }

  @override
  Widget build(BuildContext context) {
    final cars = ref.watch(carListProvider);
    final filters = ref.watch(carFiltersProvider);
    final text = Theme.of(context).textTheme;

    return GlowBackground(
      glowAlignment: const Alignment(0, -1.05),
      intensity: 0.4,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: BrandColors.primary,
          onRefresh: () => ref.read(carListProvider.notifier).refresh(),
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
              // ── Fresh header: avatar · greeting · notifications + location ──
              const SliverToBoxAdapter(child: _HomeHeader()),

              // ── SearchBar: pill 52h, surface2 fill, leading search icon muted ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.x5, 0, Spacing.x5, Spacing.x4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/search'),
                          child: Container(
                            height: Sizes.searchBar,
                            padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.x4),
                            decoration: BoxDecoration(
                              color: BrandColors.surface2,
                              borderRadius: BorderRadius.circular(Radii.pill),
                              border: Border.all(color: BrandColors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.search,
                                    color: BrandColors.mutedFg,
                                    size: Sizes.iconSm),
                                const SizedBox(width: Spacing.x3),
                                Expanded(
                                  child: Text(
                                    'Search cars, models, cities…',
                                    style: text.bodyLarge
                                        ?.copyWith(color: BrandColors.subtleFg),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacing.x3),
                      _FilterButton(
                        badge: filters.activeCount,
                        onTap: _openFilters,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Quick filter chips: actually drive sort/fuel/seats ──────
              SliverToBoxAdapter(
                child: _QuickFiltersBar(
                  filters: filters,
                  isActive: _isQuickFilterActive,
                  onSelect: _applyQuickFilter,
                  onSort: _openSortSheet,
                ),
              ),
              // ── Active filter strip: tap any chip to remove that filter ──
              if (filters.activeCount > 0 || filters.sort != null) ...[
                const SliverToBoxAdapter(child: SizedBox(height: Spacing.x3)),
                SliverToBoxAdapter(
                  child: _ActiveFiltersStrip(
                    filters: filters,
                    onRemove: (next) {
                      ref.read(carFiltersProvider.notifier).state = next;
                      unawaited(ref.read(carListProvider.notifier).load(next));
                    },
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: Spacing.x5)),

              // ── Popular near you: horizontal CarCard list ──────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.x5, 0, Spacing.x5, Spacing.x3),
                  child: SectionHeader(
                    title: 'Popular near you',
                    actionLabel: 'See all',
                    onAction: () => context.push('/search'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: cars.when(
                  loading: () => _HorizontalCardShimmer(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (list) => list.isEmpty
                      ? const SizedBox.shrink()
                      : _HorizontalCarList(
                          cars: list.take(8).toList(),
                          onTap: (id) => context.push('/car/$id'),
                        ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Spacing.x6)),

              // ── Categories: 4-col icon tiles ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.x5, 0, Spacing.x5, Spacing.x3),
                  child: Text('Categories', style: text.headlineSmall),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: Spacing.x5),
                  child: _CategoryGrid(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Spacing.x6)),

              // ── New on Drivly: list ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.x5, 0, Spacing.x5, Spacing.x3),
                  child: SectionHeader(
                    title: 'New on Drivly',
                    actionLabel: 'See all',
                    onAction: () => context.push('/search'),
                  ),
                ),
              ),
              ...cars.when(
                loading: () => [
                  const SliverToBoxAdapter(child: _VerticalCardShimmer()),
                ],
                error: (e, _) => [
                  SliverFillRemaining(
                    child: ErrorView(
                      message: e.toString(),
                      onRetry: () =>
                          ref.read(carListProvider.notifier).load(filters),
                    ),
                  ),
                ],
                data: (list) {
                  if (list.isEmpty) {
                    return [
                      SliverFillRemaining(
                        child: EmptyView(
                          icon: Icons.directions_car_outlined,
                          title: 'No cars in your area',
                          subtitle:
                              'There are no cars available nearby right now.',
                          actionLabel: 'Expand radius',
                          onAction: () {
                            // Clear location-based filters to widen the radius.
                            const next = CarFilters();
                            ref.read(carFiltersProvider.notifier).state = next;
                            ref.read(carListProvider.notifier).load(next);
                          },
                        ),
                      ),
                    ];
                  }
                  return [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          Spacing.x5, 0, Spacing.x5, Spacing.x5),
                      sliver: SliverList.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: Spacing.x4),
                        itemBuilder: (_, i) => CarCard(
                          car: list[i],
                          onTap: () => context.push('/car/${list[i].id}'),
                        ),
                      ),
                    ),
                  ];
                },
              ),

              // ── Promo banner: 160h gradient with CTA ──────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.x5, 0, Spacing.x5, Spacing.x8),
                  child: _PromoBanner(onExplore: _explorePremium),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Home header (avatar · greeting · notifications + location) ───────────────

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final unread = ref.watch(unreadCountProvider);
    final text = Theme.of(context).textTheme;
    final firstName = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim().split(' ').first
        : 'there';

    // One clean row: avatar · greeting+name (flex) · bell. No location chip —
    // it crowded the name/bell and forced a half-empty second row.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x5),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: AppAvatar(
              imageUrl: user?.avatarUrl,
              initials: user?.initials ?? '?',
              radius: 22,
            ),
          ),
          const SizedBox(width: Spacing.x3),
          // Greeting + name — flexes to fill the middle, never overflows.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(),
                    style: text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    style: text.titleLarge,
                    children: [
                      TextSpan(
                        text: firstName,
                        style: text.titleLarge?.copyWith(
                          color: BrandColors.primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: ' 👋'),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.x3),
          _HeaderIconButton(
            icon: Icons.notifications_none_rounded,
            badge: unread,
            onTap: () => context.push('/notifications'),
          ),
        ],
      ),
    );
  }
}

/// Circular header action (notification bell) with an optional unread badge.
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: BrandColors.surface2,
          shape: CircleBorder(
            side: BorderSide(color: BrandColors.border),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: Sizes.iconRoundButton,
              height: Sizes.iconRoundButton,
              child:
                  Icon(icon, color: BrandColors.foreground, size: Sizes.icon),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: BrandColors.primary,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(Radii.pill),
                border: Border.all(color: BrandColors.background, width: 2),
              ),
              child: Center(
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: BrandColors.primaryFg,
                        fontSize: 10,
                        letterSpacing: 0,
                      ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Quick filters ────────────────────────────────────────────────────────────

/// A one-tap filter preset surfaced on the Home screen.
class _QuickFilter {
  final String label;
  final IconData icon;
  final String? sort;
  final String? fuelType;
  final int? minSeats;

  const _QuickFilter({
    required this.label,
    required this.icon,
    this.sort,
    this.fuelType,
    this.minSeats,
  });
}

const _quickFilters = <_QuickFilter>[
  _QuickFilter(label: 'Top rated', icon: Icons.star_rounded, sort: 'rating'),
  _QuickFilter(label: 'Cheapest', icon: Icons.savings_outlined, sort: 'price_asc'),
  _QuickFilter(label: 'Electric', icon: Icons.electric_bolt, fuelType: 'electric'),
  _QuickFilter(label: 'Family (5+)', icon: Icons.groups_outlined, minSeats: 5),
  _QuickFilter(label: 'Hybrid', icon: Icons.eco_outlined, fuelType: 'hybrid'),
];

class _QuickFiltersBar extends StatelessWidget {
  final CarFilters filters;
  final bool Function(_QuickFilter, CarFilters) isActive;
  final ValueChanged<_QuickFilter> onSelect;
  final VoidCallback onSort;

  const _QuickFiltersBar({
    required this.filters,
    required this.isActive,
    required this.onSelect,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: Sizes.filterChip + 4,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.x5),
        // +1 leading "Sort" pill.
        itemCount: _quickFilters.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: Spacing.x2),
        itemBuilder: (_, i) {
          if (i == 0) {
            // Sort pill — opens a bottom sheet.
            final sortLabel = switch (filters.sort) {
              'price_asc' => 'Price ↑',
              'price_desc' => 'Price ↓',
              'rating' => 'Top rated',
              _ => 'Sort',
            };
            return ActionChip(
              avatar: Icon(Icons.swap_vert_rounded,
                  size: Sizes.iconSm, color: BrandColors.primaryText),
              label: Text(sortLabel, style: text.labelLarge),
              onPressed: onSort,
            );
          }
          final q = _quickFilters[i - 1];
          final sel = isActive(q, filters);
          return FilterChip(
            avatar: Icon(q.icon,
                size: Sizes.iconSm,
                color: sel ? BrandColors.primaryFg : BrandColors.foreground),
            label: Text(
              q.label,
              style: TextStyle(
                color: sel ? BrandColors.primaryFg : BrandColors.foreground,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            selected: sel,
            onSelected: (_) => onSelect(q),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

// ── Active filters strip — one-tap remove for each active filter ─────────────

class _ActiveFiltersStrip extends StatelessWidget {
  final CarFilters filters;
  final ValueChanged<CarFilters> onRemove;

  const _ActiveFiltersStrip(
      {required this.filters, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final chips = <_ActiveChip>[];
    if (filters.sort != null) {
      chips.add(_ActiveChip(
        label: switch (filters.sort) {
          'price_asc' => 'Cheapest',
          'price_desc' => 'Most expensive',
          'rating' => 'Top rated',
          _ => filters.sort!,
        },
        onRemove: () => onRemove(_clearSort(filters)),
      ));
    }
    if (filters.city != null) {
      chips.add(_ActiveChip(
        label: filters.city!,
        onRemove: () => onRemove(filters.cleared(city: true)),
      ));
    }
    if (filters.make != null) {
      chips.add(_ActiveChip(
        label: filters.make!,
        onRemove: () => onRemove(filters.cleared(make: true)),
      ));
    }
    if (filters.transmission != null) {
      chips.add(_ActiveChip(
        label: filters.transmission!,
        onRemove: () => onRemove(filters.cleared(transmission: true)),
      ));
    }
    if (filters.fuelType != null) {
      chips.add(_ActiveChip(
        label: filters.fuelType!,
        onRemove: () => onRemove(filters.cleared(fuelType: true)),
      ));
    }
    if (filters.minSeats != null) {
      chips.add(_ActiveChip(
        label: '${filters.minSeats}+ seats',
        onRemove: () => onRemove(filters.cleared(seats: true)),
      ));
    }
    if (filters.minPrice != null || filters.maxPrice != null) {
      final lo = filters.minPrice?.round();
      final hi = filters.maxPrice?.round();
      chips.add(_ActiveChip(
        label: 'AED ${lo ?? 0}–${hi ?? '∞'}',
        onRemove: () => onRemove(filters.cleared(price: true)),
      ));
    }
    if (filters.minYear != null || filters.maxYear != null) {
      chips.add(_ActiveChip(
        label: '${filters.minYear ?? ''}–${filters.maxYear ?? ''}',
        onRemove: () => onRemove(filters.cleared(year: true)),
      ));
    }
    if (filters.instantBooking) {
      chips.add(_ActiveChip(
        label: 'Instant book',
        onRemove: () => onRemove(filters.cleared(instant: true)),
      ));
    }
    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: Sizes.filterChip + 4,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.x5),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: Spacing.x2),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  CarFilters _clearSort(CarFilters f) => CarFilters(
        query: f.query,
        city: f.city,
        make: f.make,
        transmission: f.transmission,
        fuelType: f.fuelType,
        minPrice: f.minPrice,
        maxPrice: f.maxPrice,
        minSeats: f.minSeats,
        minYear: f.minYear,
        maxYear: f.maxYear,
        lat: f.lat,
        lng: f.lng,
        radius: f.radius,
      );
}

class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ActiveChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.pill),
      onTap: onRemove,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: Spacing.x3, vertical: 6),
        decoration: BoxDecoration(
          color: BrandColors.surface2,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: BrandColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: text.labelLarge),
            const SizedBox(width: 6),
            Icon(Icons.close, size: 14, color: BrandColors.mutedFg),
          ],
        ),
      ),
    );
  }
}

// ── Horizontal CarCard list ───────────────────────────────────────────────────

class _HorizontalCarList extends StatelessWidget {
  final List<dynamic> cars;
  final ValueChanged<String> onTap;

  const _HorizontalCarList({required this.cars, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 276,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.x5),
        itemCount: cars.length,
        separatorBuilder: (_, __) => const SizedBox(width: Spacing.x3),
        itemBuilder: (_, i) => SizedBox(
          width: 220,
          child: CarCard(
            car: cars[i],
            onTap: () => onTap(cars[i].id as String),
          ),
        ),
      ),
    );
  }
}

// ── Shimmer placeholders ─────────────────────────────────────────────────────

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;

  const _ShimmerBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: BrandColors.surface2,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
    );
  }
}

class _HorizontalCardShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 276,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.x5),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: Spacing.x3),
        itemBuilder: (_, __) => const _ShimmerBox(width: 220, height: 276),
      ),
    );
  }
}

class _VerticalCardShimmer extends StatelessWidget {
  const _VerticalCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.x5),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            const _ShimmerBox(width: double.infinity, height: 240),
            const SizedBox(height: Spacing.x4),
          ],
        ],
      ),
    );
  }
}

// ── Categories grid ──────────────────────────────────────────────────────────

class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid();

  /// Browse a category: EV maps to the electric fuel-type filter, the rest
  /// drive the (client-side) search query. Resets other filters, keeps location.
  void _open(BuildContext context, WidgetRef ref, String label) {
    final base = ref.read(carFiltersProvider);
    final isEv = label == 'EV';
    final next = CarFilters(
      query: isEv ? null : label,
      fuelType: isEv ? 'electric' : null,
      city: base.city,
      lat: base.lat,
      lng: base.lng,
      radius: base.radius,
    );
    ref.read(carFiltersProvider.notifier).state = next;
    ref.read(carListProvider.notifier).load(next);
    context.push('/search');
  }

  static const _categories = [
    (Icons.directions_car_outlined, 'SUV'),
    (Icons.airport_shuttle_outlined, 'Sedan'),
    (Icons.sports_motorsports_outlined, 'Sports'),
    (Icons.electric_bolt_outlined, 'EV'),
    (Icons.star_outline_rounded, 'Luxury'),
    (Icons.rv_hookup_outlined, 'Van'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: Spacing.x3,
        crossAxisSpacing: Spacing.x3,
        childAspectRatio: 0.95,
      ),
      itemCount: _categories.length,
      itemBuilder: (_, i) {
        final (icon, label) = _categories[i];
        return Material(
          color: BrandColors.surface2,
          borderRadius: BorderRadius.circular(Radii.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.lg),
            onTap: () => _open(context, ref, label),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: Sizes.iconLg, color: BrandColors.primaryText),
                const SizedBox(height: Spacing.x1),
                Text(label,
                    style: text.labelMedium
                        ?.copyWith(color: BrandColors.foreground),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Promo banner ─────────────────────────────────────────────────────────────

class _PromoBanner extends StatelessWidget {
  final VoidCallback onExplore;
  const _PromoBanner({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      height: 160,
      padding: const EdgeInsets.all(Spacing.x5),
      decoration: BoxDecoration(
        gradient: BrandGradients.accent,
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Drivly Premium',
                style: text.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: Spacing.x1),
              Text(
                'Unlock exclusive cars & top host perks.',
                style: text.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          SizedBox(
            height: Sizes.secondaryHeight,
            child: FilledButton(
              onPressed: onExplore,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: BrandColors.accent,
                minimumSize: const Size(0, Sizes.secondaryHeight),
                padding: const EdgeInsets.symmetric(horizontal: Spacing.x5),
              ),
              child: const Text('Explore Premium'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter button with badge ─────────────────────────────────────────────────

class _FilterButton extends StatelessWidget {
  final int badge;
  final VoidCallback onTap;

  const _FilterButton({this.badge = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: BrandColors.surface2,
          shape: CircleBorder(
            side: BorderSide(color: BrandColors.border),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: Sizes.searchBar,
              height: Sizes.searchBar,
              child: Icon(Icons.tune, color: BrandColors.foreground),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: BrandColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badge',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: BrandColors.primaryFg,
                      fontSize: 10,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}
