import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/car_filters.dart';

/// Shows the filter bottom sheet and returns the chosen [CarFilters], or null
/// if dismissed.
Future<CarFilters?> showFiltersSheet(
  BuildContext context,
  CarFilters current,
) {
  return showModalBottomSheet<CarFilters>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FiltersSheet(initial: current),
  );
}

class _FiltersSheet extends StatefulWidget {
  final CarFilters initial;
  const _FiltersSheet({required this.initial});

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late RangeValues _price;
  String? _transmission;
  String? _fuel;
  int? _minSeats;
  String? _sort;

  static const _maxPrice = 500.0;

  @override
  void initState() {
    super.initState();
    _price = RangeValues(
      widget.initial.minPrice ?? 0,
      widget.initial.maxPrice ?? _maxPrice,
    );
    _transmission = widget.initial.transmission;
    _fuel = widget.initial.fuelType;
    _minSeats = widget.initial.minSeats;
    _sort = widget.initial.sort;
  }

  void _reset() {
    setState(() {
      _price = const RangeValues(0, _maxPrice);
      _transmission = null;
      _fuel = null;
      _minSeats = null;
      _sort = null;
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      widget.initial.copyWith(
        minPrice: _price.start == 0 ? null : _price.start,
        maxPrice: _price.end == _maxPrice ? null : _price.end,
        transmission: _transmission,
        fuelType: _fuel,
        minSeats: _minSeats,
        sort: _sort,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: Spacing.x3),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: BrandColors.border,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(Spacing.x5),
              children: [
                Text('Filters',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: Spacing.x5),
                _label('Price per day'),
                RangeSlider(
                  values: _price,
                  min: 0,
                  max: _maxPrice,
                  divisions: 50,
                  activeColor: BrandColors.primary,
                  labels: RangeLabels(
                    '\$${_price.start.round()}',
                    '\$${_price.end.round()}',
                  ),
                  onChanged: (v) => setState(() => _price = v),
                ),
                const SizedBox(height: Spacing.x4),
                _label('Transmission'),
                _chips(
                  const {'automatic': 'Automatic', 'manual': 'Manual'},
                  _transmission,
                  (v) => setState(() => _transmission = v),
                ),
                const SizedBox(height: Spacing.x4),
                _label('Fuel'),
                _chips(
                  const {
                    'petrol': 'Petrol',
                    'diesel': 'Diesel',
                    'electric': 'Electric',
                    'hybrid': 'Hybrid',
                  },
                  _fuel,
                  (v) => setState(() => _fuel = v),
                ),
                const SizedBox(height: Spacing.x4),
                _label('Minimum seats'),
                _chips(
                  const {'2': '2', '4': '4', '5': '5', '7': '7+'},
                  _minSeats?.toString(),
                  (v) => setState(
                      () => _minSeats = v == null ? null : int.parse(v)),
                ),
                const SizedBox(height: Spacing.x4),
                _label('Sort by'),
                _chips(
                  const {
                    'price_asc': 'Price ↑',
                    'price_desc': 'Price ↓',
                    'rating': 'Rating',
                  },
                  _sort,
                  (v) => setState(() => _sort = v),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.x4),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: Spacing.x3),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _apply,
                      child: const Text('Apply filters'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: Spacing.x2),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _chips(
    Map<String, String> options,
    String? selected,
    ValueChanged<String?> onSelect,
  ) {
    return Wrap(
      spacing: Spacing.x2,
      children: options.entries.map((e) {
        final isSel = selected == e.key;
        return ChoiceChip(
          label: Text(e.value),
          selected: isSel,
          onSelected: (_) => onSelect(isSel ? null : e.key),
        );
      }).toList(),
    );
  }
}
