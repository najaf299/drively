import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/car_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/domain/providers/auth_provider.dart';
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

  void _selectDateFilter(String? key) {
    final filters = ref.read(carFiltersProvider);
    final updated = filters.copyWith(sort: key);
    ref.read(carFiltersProvider.notifier).state = updated;
    ref.read(carListProvider.notifier).load(updated);
  }

  @override
  Widget build(BuildContext context) {
    final cars = ref.watch(carListProvider);
    final filters = ref.watch(carFiltersProvider);
    final user = ref.watch(authProvider).user;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: BrandColors.primary,
        onRefresh: () => ref.read(carListProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            // ── AppBar greeting: 'Hi, {name}' titleLarge + location chip ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Greeting overline.
                          Text(
                            'WELCOME BACK',
                            style: text.labelSmall?.copyWith(
                              color: BrandColors.mutedFg,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          // 'Hi, {name}' — headline, name in primary.
                          Text.rich(
                            TextSpan(
                              style: text.headlineSmall,
                              children: [
                                const TextSpan(text: 'Hi, '),
                                TextSpan(
                                  text: (user?.name.trim().isNotEmpty ?? false)
                                      ? user!.name.trim().split(' ').first
                                      : 'there',
                                  style: text.headlineSmall
                                      ?.copyWith(color: BrandColors.primary),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: Spacing.x2),
                          // Location chip — surface2 pill.
                          _LocationChip(
                            location: 'Karachi, PK',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Spacing.x4),
                    // Avatar — aligned to the top of the greeting block.
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: BrandColors.border, width: 1.5),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: CircleAvatar(
                        radius: Sizes.avatarSm,
                        backgroundColor: BrandColors.accent,
                        child: Text(
                          (user?.name.trim().isNotEmpty ?? false)
                              ? user!.name.trim()[0].toUpperCase()
                              : '?',
                          style: text.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
                            borderRadius:
                                BorderRadius.circular(Radii.pill),
                            border: Border.all(color: BrandColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search,
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

            // ── Date filter chips: Today / This week / Weekend / Custom ──
            SliverToBoxAdapter(
              child: _DateChips(
                selected: filters.sort,
                onSelect: _selectDateFilter,
              ),
            ),
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
                const SliverToBoxAdapter(
                    child: _VerticalCardShimmer()),
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
                          ref
                              .read(carListProvider.notifier)
                              .load(next);
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
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    Spacing.x5, 0, Spacing.x5, Spacing.x8),
                child: _PromoBanner(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Location chip ───────────────────────────────────────────────────────────

class _LocationChip extends StatelessWidget {
  final String location;
  final VoidCallback onTap;

  const _LocationChip({required this.location, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.x3, vertical: Spacing.x1 + 2),
        decoration: BoxDecoration(
          color: BrandColors.surface2,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: BrandColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on,
                color: BrandColors.primary, size: Sizes.iconSm),
            const SizedBox(width: Spacing.x1),
            Flexible(
              child: Text(
                location,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: BrandColors.foreground),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Spacing.x1),
            const Icon(Icons.expand_more,
                color: BrandColors.mutedFg, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Date filter chips ────────────────────────────────────────────────────────

class _DateChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _DateChips({required this.selected, required this.onSelect});

  static const _items = {
    'today': 'Today',
    'week': 'This week',
    'weekend': 'Weekend',
    'custom': 'Custom',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Sizes.filterChip + 4,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.x5),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: Spacing.x2),
        itemBuilder: (_, i) {
          final entry = _items.entries.elementAt(i);
          final isSel = selected == entry.key;
          return ChoiceChip(
            label: Text(entry.value),
            selected: isSel,
            onSelected: (_) => onSelect(isSel ? null : entry.key),
            showCheckmark: false,
          );
        },
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
      padding:
          const EdgeInsets.symmetric(horizontal: Spacing.x5),
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

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  static const _categories = [
    (Icons.directions_car_outlined, 'SUV'),
    (Icons.airport_shuttle_outlined, 'Sedan'),
    (Icons.sports_motorsports_outlined, 'Sports'),
    (Icons.electric_bolt_outlined, 'EV'),
    (Icons.star_outline_rounded, 'Luxury'),
    (Icons.rv_hookup_outlined, 'Van'),
  ];

  @override
  Widget build(BuildContext context) {
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
            onTap: () {},
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: Sizes.iconLg, color: BrandColors.primary),
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
  const _PromoBanner();

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
                style: text.headlineSmall
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: Spacing.x1),
              Text(
                'Unlock exclusive cars & top host perks.',
                style: text.bodyMedium
                    ?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          SizedBox(
            height: Sizes.secondaryHeight,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: BrandColors.accent,
                minimumSize: const Size(0, Sizes.secondaryHeight),
                padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.x5),
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
          shape: const CircleBorder(
            side: BorderSide(color: BrandColors.border),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const SizedBox(
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
              decoration: const BoxDecoration(
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
