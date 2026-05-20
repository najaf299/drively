import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/car_card.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/car_filters.dart';
import '../../domain/providers/car_provider.dart';
import 'filters_sheet.dart';

/// Customer landing (Discover): location header, a search/date pill + filter
/// button, category chips and a paginated car list.
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

  void _selectFuel(String? fuel) {
    final updated =
        ref.read(carFiltersProvider).copyWith().cleared(fuelType: true);
    final next = fuel == null ? updated : updated.copyWith(fuelType: fuel);
    ref.read(carFiltersProvider.notifier).state = next;
    ref.read(carListProvider.notifier).load(next);
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
        onRefresh: () => ref.read(carListProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            // ── Header: greeting + location + avatar ───────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Greeting: muted line with the user's name in lime.
                          Text.rich(
                            TextSpan(
                              style: text.headlineSmall
                                  ?.copyWith(color: BrandColors.mutedFg),
                              children: [
                                const TextSpan(text: 'Hi, '),
                                TextSpan(
                                  text: (user?.name.trim().isNotEmpty ?? false)
                                      ? user!.name.trim().split(' ').first
                                      : 'there',
                                  style: const TextStyle(
                                      color: BrandColors.primary),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: BrandColors.primary,
                                  size: Sizes.icon),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Karachi, PK',
                                  style: text.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Spacing.x3),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: BrandColors.accent,
                      child: Text(
                        (user?.name.trim().isNotEmpty ?? false)
                            ? user!.name.trim()[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Search/date pill + filter button ───────────────────────────
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
                          height: Sizes.secondaryHeight,
                          padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.x4),
                          decoration: BoxDecoration(
                            color: BrandColors.surface2,
                            borderRadius: BorderRadius.circular(Radii.pill),
                            border: Border.all(color: BrandColors.border),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search, color: BrandColors.mutedFg),
                              SizedBox(width: Spacing.x3),
                              Text('When?  ·  Add dates',
                                  style:
                                      TextStyle(color: BrandColors.mutedFg)),
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
            // ── Category chips ─────────────────────────────────────────────
            SliverToBoxAdapter(child: _categoryChips(filters)),
            // ── Section title ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.x5, Spacing.x5, Spacing.x5, Spacing.x3),
                child: Text('Top picks near you',
                    style: text.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
            // ── Car list ───────────────────────────────────────────────────
            ...cars.when(
              loading: () => [const SliverFillRemaining(child: LoadingView())],
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
                    const SliverFillRemaining(
                      child: EmptyView(
                        icon: Icons.directions_car_outlined,
                        title: 'No cars found',
                        subtitle: 'Try adjusting your filters or search area.',
                      ),
                    ),
                  ];
                }
                return [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        Spacing.x5, 0, Spacing.x5, Spacing.x6),
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
          ],
        ),
      ),
    );
  }

  /// Category chips. "All" clears the fuel filter; the rest reuse the existing
  /// fuel filter values via [_selectFuel].
  Widget _categoryChips(CarFilters filters) {
    const fuels = {
      'electric': 'Electric',
      'hybrid': 'Hybrid',
      'petrol': 'Petrol',
      'diesel': 'Diesel',
    };
    final chips = <Widget>[
      _CategoryChip(
        label: 'All',
        selected: filters.fuelType == null,
        onTap: () => _selectFuel(null),
      ),
      ...fuels.entries.map((e) {
        final selected = filters.fuelType == e.key;
        return _CategoryChip(
          label: e.value,
          selected: selected,
          onTap: () => _selectFuel(selected ? null : e.key),
        );
      }),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.x5),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: Spacing.x2),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }
}

/// Selectable category chip backed by the theme's [ChipThemeData].
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }
}

/// 48px round filter button (tune icon) with an optional active-count badge.
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
          color: BrandColors.surface,
          shape: const CircleBorder(
            side: BorderSide(color: BrandColors.border),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const SizedBox(
              width: Sizes.secondaryHeight,
              height: Sizes.secondaryHeight,
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
                style: const TextStyle(
                  color: BrandColors.primaryFg,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
