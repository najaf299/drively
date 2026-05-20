import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../domain/car_filters.dart';
import '../../domain/providers/car_provider.dart';

/// Shows the filter bottom sheet and returns the chosen [CarFilters], or null
/// if dismissed.
Future<CarFilters?> showFiltersSheet(
  BuildContext context,
  CarFilters current,
) {
  return showModalBottomSheet<CarFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: BrandColors.surface,
    builder: (_) => _FiltersSheet(initial: current),
  );
}

class _FiltersSheet extends ConsumerStatefulWidget {
  final CarFilters initial;
  const _FiltersSheet({required this.initial});

  @override
  ConsumerState<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<_FiltersSheet> {
  late RangeValues _price;
  String? _transmission;
  String? _fuel; // "Vehicle type" maps to the fuel filter.
  int? _minSeats;
  String? _sort;
  bool _instantBooking = false; // cosmetic; not part of CarFilters.

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
      _instantBooking = false;
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
    final text = Theme.of(context).textTheme;
    final count = ref.watch(carListProvider).valueOrNull?.length;
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
              color: BrandColors.borderStrong,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
          // Header: Filters + Reset.
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Spacing.x5, Spacing.x4, Spacing.x3, 0),
            child: Row(
              children: [
                Text('Filters', style: text.headlineSmall),
                const Spacer(),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(
                  Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x5),
              children: [
                _label('Price range / day'),
                RangeSlider(
                  values: _price,
                  min: 0,
                  max: _maxPrice,
                  divisions: 50,
                  labels: RangeLabels(
                    '\$${_price.start.round()}',
                    '\$${_price.end.round()}',
                  ),
                  onChanged: (v) => setState(() => _price = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('\$${_price.start.round()}',
                        style: const TextStyle(color: BrandColors.mutedFg)),
                    Text(
                        _price.end >= _maxPrice
                            ? '\$${_maxPrice.round()}+'
                            : '\$${_price.end.round()}',
                        style: const TextStyle(color: BrandColors.mutedFg)),
                  ],
                ),
                const SizedBox(height: Spacing.x5),
                _label('Vehicle type'),
                _pillGrid(
                  const {
                    'electric': 'Electric',
                    'hybrid': 'Hybrid',
                    'petrol': 'Petrol',
                    'diesel': 'Diesel',
                  },
                  _fuel,
                  (v) => setState(() => _fuel = v),
                ),
                const SizedBox(height: Spacing.x5),
                _label('Transmission'),
                _pillGrid(
                  const {'automatic': 'Automatic', 'manual': 'Manual'},
                  _transmission,
                  (v) => setState(() => _transmission = v),
                ),
                const SizedBox(height: Spacing.x5),
                _label('Minimum seats'),
                _pillGrid(
                  const {'2': '2', '4': '4', '5': '5', '7': '7+'},
                  _minSeats?.toString(),
                  (v) =>
                      setState(() => _minSeats = v == null ? null : int.parse(v)),
                ),
                const SizedBox(height: Spacing.x5),
                _label('Sort by'),
                _pillGrid(
                  const {
                    'price_asc': 'Price ↑',
                    'price_desc': 'Price ↓',
                    'rating': 'Rating',
                  },
                  _sort,
                  (v) => setState(() => _sort = v),
                ),
                const SizedBox(height: Spacing.x5),
                _label('Features'),
                _FeatureToggle(
                  icon: Icons.bolt,
                  label: 'Instant booking',
                  value: _instantBooking,
                  onChanged: (v) => setState(() => _instantBooking = v),
                ),
              ],
            ),
          ),
          // Bottom full-width "Show N cars" primary CTA.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.x4),
              child: FilledButton(
                onPressed: _apply,
                child: Text(count == null ? 'Show cars' : 'Show $count cars'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: Spacing.x3),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );

  /// A wrap of selectable stadium pills (active = lime + dark text).
  Widget _pillGrid(
    Map<String, String> options,
    String? selected,
    ValueChanged<String?> onSelect,
  ) {
    return Wrap(
      spacing: Spacing.x2,
      runSpacing: Spacing.x2,
      children: options.entries.map((e) {
        final isSel = selected == e.key;
        return GestureDetector(
          onTap: () => onSelect(isSel ? null : e.key),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.x4, vertical: 10),
            decoration: BoxDecoration(
              color: isSel ? BrandColors.primary : BrandColors.surface2,
              borderRadius: BorderRadius.circular(Radii.pill),
              border: Border.all(
                color: isSel ? BrandColors.primary : BrandColors.border,
              ),
            ),
            child: Text(
              e.value,
              style: TextStyle(
                color: isSel ? BrandColors.primaryFg : BrandColors.foreground,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// A feature row on a nested surface with a real [Switch] (theme-styled).
class _FeatureToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _FeatureToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.x4, vertical: Spacing.x2),
      decoration: BoxDecoration(
        color: BrandColors.surface2,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: BrandColors.primary, size: Sizes.icon),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
