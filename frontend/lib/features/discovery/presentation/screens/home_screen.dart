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

/// Customer landing: search entry, quick fuel filters and a paginated car list.
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

    return RefreshIndicator(
      onRefresh: () => ref.read(carListProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 132,
            backgroundColor: BrandColors.background,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.fromLTRB(Spacing.x5, 0, Spacing.x5, 14),
              title: Text(
                'Find your drive, ${user?.name.split(' ').first ?? 'there'}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.x5, 0, Spacing.x5, Spacing.x3),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/search'),
                      child: Container(
                        height: 48,
                        padding:
                            const EdgeInsets.symmetric(horizontal: Spacing.x4),
                        decoration: BoxDecoration(
                          color: BrandColors.surface,
                          borderRadius: BorderRadius.circular(Radii.pill),
                          border: Border.all(color: BrandColors.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: BrandColors.mutedFg),
                            SizedBox(width: Spacing.x3),
                            Text('Search cars, cities…',
                                style: TextStyle(color: BrandColors.mutedFg)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.x3),
                  _RoundButton(
                    icon: Icons.tune,
                    badge: filters.activeCount,
                    onTap: _openFilters,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _fuelChips(filters)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x2),
              child: Text('Top picks near you',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
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
    );
  }

  Widget _fuelChips(CarFilters filters) {
    const fuels = {
      'electric': 'Electric',
      'hybrid': 'Hybrid',
      'petrol': 'Petrol',
      'diesel': 'Diesel',
    };
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.x5),
        children: fuels.entries.map((e) {
          final selected = filters.fuelType == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: Spacing.x2),
            child: ChoiceChip(
              label: Text(e.value),
              selected: selected,
              onSelected: (_) => _selectFuel(selected ? null : e.key),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, this.badge = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
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
              width: 48,
              height: 48,
              child: Icon(Icons.tune, color: BrandColors.foreground),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: 0,
            top: 0,
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
