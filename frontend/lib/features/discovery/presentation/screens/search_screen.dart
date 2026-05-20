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

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: Spacing.x4),
          child: TextField(
            controller: _query,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Search cars, cities…',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              suffixIcon: _query.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _query.clear();
                        _onQueryChanged('');
                      },
                    ),
            ),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.tune), onPressed: _openFilters),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/map'),
        icon: const Icon(Icons.map_outlined),
        label: const Text('Map view'),
      ),
      body: Column(
        children: [
          if (filters.activeCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.x5, Spacing.x2, Spacing.x5, 0),
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
                onRetry: () => ref.read(carListProvider.notifier).load(filters),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyView(
                    icon: Icons.search_off,
                    title: 'No cars match',
                    subtitle: 'Try a different search or clear your filters.',
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
    );
  }
}
