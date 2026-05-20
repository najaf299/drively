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

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _scroll = ScrollController();
  final _query = TextEditingController();
  Timer? _debounce;

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
            // ── Top row: back + rounded search field + filter ──────────────
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
                      height: Sizes.secondaryHeight,
                      padding:
                          const EdgeInsets.symmetric(horizontal: Spacing.x4),
                      decoration: BoxDecoration(
                        color: BrandColors.surface2,
                        borderRadius: BorderRadius.circular(Radii.pill),
                        border: Border.all(color: BrandColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search,
                              color: BrandColors.mutedFg, size: 20),
                          const SizedBox(width: Spacing.x2),
                          Expanded(
                            child: TextField(
                              controller: _query,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              onChanged: _onQueryChanged,
                              style: text.bodyLarge,
                              decoration: const InputDecoration(
                                hintText: 'Search cars, cities…',
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
                                  color: BrandColors.mutedFg, size: 20),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.x3),
                  _CircleButton(icon: Icons.tune, onTap: _openFilters),
                ],
              ),
            ),
            if (filters.activeCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.x5, 0, Spacing.x5, Spacing.x2),
                child: Row(
                  children: [
                    Text(
                      '${filters.activeCount} filter'
                      '${filters.activeCount == 1 ? '' : 's'} applied',
                      style: const TextStyle(color: BrandColors.mutedFg),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // Reset everything except the free-text query.
                        final next = CarFilters(query: filters.query);
                        ref.read(carFiltersProvider.notifier).state = next;
                        ref.read(carListProvider.notifier).load(next);
                      },
                      child: const Text('Clear all'),
                    ),
                  ],
                ),
              ),
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
                          : 'No cars match',
                      subtitle: _query.text.isEmpty
                          ? 'Search by car, make or city to get started.'
                          : 'Try a different search or clear your filters.',
                    );
                  }
                  return ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsets.all(Spacing.x5),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: Spacing.x4),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/map'),
        backgroundColor: BrandColors.primary,
        foregroundColor: BrandColors.primaryFg,
        icon: const Icon(Icons.map_outlined),
        label: const Text('Map view'),
      ),
    );
  }
}

/// 44px circular icon button on a surface tile.
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.surface,
      shape: const CircleBorder(side: BorderSide(color: BrandColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: BrandColors.foreground, size: 20),
        ),
      ),
    );
  }
}
