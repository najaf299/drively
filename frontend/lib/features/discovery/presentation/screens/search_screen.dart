import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/car_card.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../data/recent_searches.dart';
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
  final _searchFocus = FocusNode();
  Timer? _debounce;
  bool _mapMode = false; // List ↔ Map toggle.
  List<String> _recents = const [];

  @override
  void initState() {
    super.initState();
    _query.text = ref.read(carFiltersProvider).query ?? '';
    _recents = RecentSearches.all();
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
    _searchFocus.dispose();
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

  Future<void> _onSubmitted(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    await RecentSearches.add(trimmed);
    if (mounted) setState(() => _recents = RecentSearches.all());
  }

  Future<void> _useRecent(String term) async {
    _query.text = term;
    _searchFocus.unfocus();
    _onQueryChanged(term);
    await RecentSearches.add(term);
    if (mounted) setState(() => _recents = RecentSearches.all());
  }

  Future<void> _removeRecent(String term) async {
    await RecentSearches.remove(term);
    if (mounted) setState(() => _recents = RecentSearches.all());
  }

  Future<void> _clearRecents() async {
    await RecentSearches.clear();
    if (mounted) setState(() => _recents = const []);
  }

  void _setSort(String? sort) {
    final f = ref.read(carFiltersProvider);
    final clean = CarFilters(
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
      sort: sort,
      lat: f.lat,
      lng: f.lng,
      radius: f.radius,
    );
    ref.read(carFiltersProvider.notifier).state = clean;
    ref.read(carListProvider.notifier).load(clean);
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
                          Icon(Icons.search,
                              color: BrandColors.mutedFg,
                              size: Sizes.iconSm),
                          const SizedBox(width: Spacing.x2),
                          Expanded(
                            child: TextField(
                              controller: _query,
                              focusNode: _searchFocus,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              onChanged: _onQueryChanged,
                              onSubmitted: _onSubmitted,
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
                              child: Icon(Icons.close,
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
                            decoration: BoxDecoration(
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

            // ── Sort segment row (visible, always-on) ───────────────────────
            _SortSegment(selected: filters.sort, onSelect: _setSort),
            const SizedBox(height: Spacing.x2),

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
                    // Empty + no query + has recents → show recent searches.
                    if (_query.text.isEmpty &&
                        filters.activeCount == 0 &&
                        _recents.isNotEmpty) {
                      return _RecentsPane(
                        recents: _recents,
                        onUse: _useRecent,
                        onRemove: _removeRecent,
                        onClear: _clearRecents,
                      );
                    }
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

// ── Sort segmented row ───────────────────────────────────────────────────────

class _SortSegment extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _SortSegment({required this.selected, required this.onSelect});

  static const _options = <_SortOption>[
    _SortOption(null, 'Newest'),
    _SortOption('rating', 'Top rated'),
    _SortOption('price_asc', 'Price ↑'),
    _SortOption('price_desc', 'Price ↓'),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: Sizes.filterChip + 4,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.x5),
        itemCount: _options.length,
        separatorBuilder: (_, __) => const SizedBox(width: Spacing.x2),
        itemBuilder: (_, i) {
          final opt = _options[i];
          final sel = selected == opt.key;
          return ChoiceChip(
            label: Text(
              opt.label,
              style: text.labelLarge?.copyWith(
                color: sel ? BrandColors.primaryFg : BrandColors.foreground,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            selected: sel,
            showCheckmark: false,
            onSelected: (_) => onSelect(opt.key),
          );
        },
      ),
    );
  }
}

class _SortOption {
  final String? key;
  final String label;
  const _SortOption(this.key, this.label);
}

// ── Recent searches pane ─────────────────────────────────────────────────────

class _RecentsPane extends StatelessWidget {
  final List<String> recents;
  final ValueChanged<String> onUse;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  const _RecentsPane({
    required this.recents,
    required this.onUse,
    required this.onRemove,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x8),
      children: [
        Row(
          children: [
            Text('Recent searches', style: text.titleMedium),
            const Spacer(),
            TextButton(onPressed: onClear, child: const Text('Clear all')),
          ],
        ),
        const SizedBox(height: Spacing.x2),
        ...recents.map(
          (term) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.history, color: BrandColors.mutedFg),
            title: Text(term),
            trailing: IconButton(
              icon: Icon(Icons.close, color: BrandColors.mutedFg, size: 18),
              onPressed: () => onRemove(term),
            ),
            onTap: () => onUse(term),
          ),
        ),
      ],
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
      shape: CircleBorder(
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
