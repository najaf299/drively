import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/car_card.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/car_filters.dart';
import '../../domain/providers/car_provider.dart';
import 'filters_sheet.dart';

/// Active-search screen — spec §7.8.
/// List ↔ Map toggle top-right; 2-col CarCard grid in list mode.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _scroll = ScrollController();
  final _query = TextEditingController();
  Timer? _debounce;
  bool _mapMode = false; // List ↔ Map toggle.

  @override
  void initState() {
    super.initState();
    _query.text = ref.read(carFiltersProvider).query ?? '';
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        unawaited(ref.read(carListProvider.notifier).loadMore());
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _query.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {}); // refresh the clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final next = ref.read(carFiltersProvider).copyWith(query: value);
      ref.read(carFiltersProvider.notifier).state = next;
      ref.read(carListProvider.notifier).load(next);
    });
  }

  Future<void> _openFilters() async {
    final result =
        await showFiltersSheet(context, ref.read(carFiltersProvider));
    if (result != null) {
      ref.read(carFiltersProvider.notifier).state = result;
      unawaited(ref.read(carListProvider.notifier).load(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cars = ref.watch(carListProvider);
    final filters = ref.watch(carFiltersProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Top row: back + search pill + List/Map toggle + filter ─────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.x4, Spacing.x3, Spacing.x4, Spacing.x3),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: Spacing.x3),
                  Expanded(
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
                          const Icon(Icons.search,
                              color: BrandColors.mutedFg,
                              size: Sizes.iconSm),
                          const SizedBox(width: Spacing.x2),
                          Expanded(
                            child: TextField(
                              controller: _query,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              onChanged: _onQueryChanged,
                              style: text.bodyLarge,
                              decoration: InputDecoration(
                                hintText: 'Search cars, models, cities…',
                                hintStyle: text.bodyLarge?.copyWith(
                                    color: BrandColors.subtleFg),
                                isCollapsed: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_query.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _query.clear();
                                _onQueryChanged('');
                              },
                              child: const Icon(Icons.close,
                                  color: BrandColors.mutedFg,
                                  size: Sizes.iconSm),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.x2),
                  // List ↔ Map toggle.
                  _CircleButton(
                    icon: _mapMode
                        ? Icons.view_list_outlined
                        : Icons.map_outlined,
                    onTap: () {
                      if (_mapMode) {
                        setState(() => _mapMode = false);
                      } else {
                        context.push('/map');
                      }
                    },
                  ),
                  const SizedBox(width: Spacing.x2),
                  // Filter icon with badge.
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _CircleButton(
                          icon: Icons.tune, onTap: _openFilters),
                      if (filters.activeCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 16,
                            height: 16,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: BrandColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${filters.activeCount}',
                              style: text.labelSmall?.copyWith(
                                color: BrandColors.primaryFg,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Active filter summary row ───────────────────────────────────
            if (filters.activeCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.x5, 0, Spacing.x5, Spacing.x2),
                child: Row(
                  children: [
                    Text(
                      '${filters.activeCount} filter'
                      '${filters.activeCount == 1 ? '' : 's'} applied',
                      style:
                          text.bodySmall?.copyWith(color: BrandColors.mutedFg),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        final next = CarFilters(query: filters.query);
                        ref.read(carFiltersProvider.notifier).state = next;
                        ref.read(carListProvider.notifier).load(next);
                      },
                      child: const Text('Clear all'),
                    ),
                  ],
                ),
              ),

            // ── Results ────────────────────────────────────────────────────
            Expanded(
              child: cars.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () =>
                      ref.read(carListProvider.notifier).load(filters),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return EmptyView(
                      icon: _query.text.isEmpty
                          ? Icons.travel_explore
                          : Icons.search_off,
                      title: _query.text.isEmpty
                          ? 'Find your next drive'
                          : 'No cars match these filters',
                      subtitle: _query.text.isEmpty
                          ? 'Search by car, make or city to get started.'
                          : 'Try a different search or clear your filters.',
                      actionLabel: filters.activeCount > 0
                          ? 'Reset filters'
                          : null,
                      onAction: filters.activeCount > 0
                          ? () {
                              final next = CarFilters(query: filters.query);
                              ref
                                  .read(carFiltersProvider.notifier)
                                  .state = next;
                              ref
                                  .read(carListProvider.notifier)
                                  .load(next);
                            }
                          : null,
                    );
                  }
                  // 2-col grid.
                  return GridView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(
                        Spacing.x4,
                        Spacing.x2,
                        Spacing.x4,
                        Spacing.x8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: Spacing.x3,
                      crossAxisSpacing: Spacing.x3,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: list.length,
                    itemBuilder: (_, i) => CarCard(
                      car: list[i],
                      onTap: () => context.push('/car/${list[i].id}'),
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
}

/// 44 dp circular icon button — surface fill with border.
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.surface2,
      shape: const CircleBorder(
          side: BorderSide(color: BrandColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: Sizes.iconRoundButton,
          height: Sizes.iconRoundButton,
          child: Icon(icon,
              color: BrandColors.foreground, size: Sizes.iconSm),
        ),
      ),
    );
  }
}
