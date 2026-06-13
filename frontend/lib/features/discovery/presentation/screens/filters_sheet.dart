import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../domain/car_filters.dart';
import '../../domain/providers/car_provider.dart';

/// Shows the filter bottom sheet and returns the chosen [CarFilters], or null
/// if dismissed.  Sheet top radius comes from [BottomSheetThemeData] (Radii.xxl
/// = 28), matching spec §6.
Future<CarFilters?> showFiltersSheet(
  BuildContext context,
  CarFilters current,
) {
  return showModalBottomSheet<CarFilters>(
    context: context,
    isScrollControlled: true,
    // Present over the whole screen so the bottom nav bar is covered/dimmed.
    useRootNavigator: true,
    // Let the theme's shape (xxl top corners) apply.
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
  late RangeValues _year;
  String? _transmission;
  String? _fuel;
  int? _minSeats;
  String? _sort;
  bool _instantBooking = false;

  static const _maxPrice = 500.0;
  static const _minYearAllowed = 2010.0;
  static const _maxYearAllowed = 2026.0;

  @override
  void initState() {
    super.initState();
    _price = RangeValues(
      widget.initial.minPrice ?? 0,
      widget.initial.maxPrice ?? _maxPrice,
    );
    _year = RangeValues(
      (widget.initial.minYear ?? _minYearAllowed.toInt()).toDouble(),
      (widget.initial.maxYear ?? _maxYearAllowed.toInt()).toDouble(),
    );
    _transmission = widget.initial.transmission;
    _fuel = widget.initial.fuelType;
    _minSeats = widget.initial.minSeats;
    _sort = widget.initial.sort;
    _instantBooking = widget.initial.instantBooking;
  }

  void _reset() {
    setState(() {
      _price = const RangeValues(0, _maxPrice);
      _year = const RangeValues(_minYearAllowed, _maxYearAllowed);
      _transmission = null;
      _fuel = null;
      _minSeats = null;
      _sort = null;
      _instantBooking = false;
    });
  }

  void _apply() {
    // Year range only sets bounds when the user moved off the extremes — keeps
    // the activeCount accurate so the "filters applied" badge stays honest.
    final minY = _year.start == _minYearAllowed ? null : _year.start.round();
    final maxY = _year.end == _maxYearAllowed ? null : _year.end.round();
    Navigator.pop(
      context,
      widget.initial.copyWith(
        minPrice: _price.start == 0 ? null : _price.start,
        maxPrice: _price.end == _maxPrice ? null : _price.end,
        minYear: minY,
        maxYear: maxY,
        transmission: _transmission,
        fuelType: _fuel,
        minSeats: _minSeats,
        instantBooking: _instantBooking,
        sort: _sort,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final count = ref.watch(carListProvider).valueOrNull?.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(
                top: Spacing.x3, bottom: Spacing.x1),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: BrandColors.borderStrong,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
            ),
          ),

          // ── Title: headlineSmall + Reset TextButton ───────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Spacing.x5, Spacing.x3, Spacing.x4, 0),
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

          // ── Scrollable body ───────────────────────────────────────────────
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(
                  Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x4),
              children: [
                // Price / day.
                const _SectionLabel(label: 'Price / day'),
                RangeSlider(
                  values: _price,
                  min: 0,
                  max: _maxPrice,
                  divisions: 50,
                  labels: RangeLabels(
                    'AED ${_price.start.round()}',
                    'AED ${_price.end.round()}',
                  ),
                  onChanged: (v) => setState(() => _price = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('AED ${_price.start.round()}',
                        style: text.bodySmall),
                    Text(
                      _price.end >= _maxPrice
                          ? 'AED ${_maxPrice.round()}+'
                          : 'AED ${_price.end.round()}',
                      style: text.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.x5),

                // Toggle rows.
                const _SectionLabel(label: 'Options'),
                _ToggleRow(
                  icon: Icons.bolt,
                  label: 'Instant book',
                  value: _instantBooking,
                  onChanged: (v) => setState(() => _instantBooking = v),
                ),
                const SizedBox(height: Spacing.x5),

                // Body type / fuel.
                const _SectionLabel(label: 'Fuel type'),
                _ChipGroup(
                  options: const {
                    'electric': 'Electric',
                    'hybrid': 'Hybrid',
                    'petrol': 'Petrol',
                    'diesel': 'Diesel',
                  },
                  selected: _fuel,
                  onSelect: (v) => setState(() => _fuel = v),
                ),
                const SizedBox(height: Spacing.x5),

                // Transmission.
                const _SectionLabel(label: 'Transmission'),
                _ChipGroup(
                  options: const {
                    'automatic': 'Automatic',
                    'manual': 'Manual',
                  },
                  selected: _transmission,
                  onSelect: (v) => setState(() => _transmission = v),
                ),
                const SizedBox(height: Spacing.x5),

                // Seats.
                const _SectionLabel(label: 'Seats'),
                _ChipGroup(
                  options: const {
                    '2': '2',
                    '4': '4',
                    '5': '5',
                    '7': '7+',
                  },
                  selected: _minSeats?.toString(),
                  onSelect: (v) => setState(
                      () => _minSeats = v == null ? null : int.parse(v)),
                ),
                const SizedBox(height: Spacing.x5),

                // Year range.
                const _SectionLabel(label: 'Year'),
                RangeSlider(
                  values: _year,
                  min: _minYearAllowed,
                  max: _maxYearAllowed,
                  divisions: (_maxYearAllowed - _minYearAllowed).round(),
                  labels: RangeLabels(
                    _year.start.round().toString(),
                    _year.end.round().toString(),
                  ),
                  onChanged: (v) => setState(() => _year = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_year.start.round().toString(), style: text.bodySmall),
                    Text(_year.end.round().toString(), style: text.bodySmall),
                  ],
                ),
                const SizedBox(height: Spacing.x5),

                // Sort by.
                const _SectionLabel(label: 'Sort by'),
                _ChipGroup(
                  options: const {
                    'price_asc': 'Price ↑',
                    'price_desc': 'Price ↓',
                    'rating': 'Rating',
                  },
                  selected: _sort,
                  onSelect: (v) => setState(() => _sort = v),
                ),
              ],
            ),
          ),

          // ── Sticky bottom: Reset (text) + Show N cars (filled) ────────────
          Container(
            decoration: BoxDecoration(
              color: BrandColors.surface,
              border: Border(
                  top: BorderSide(color: BrandColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.x4, Spacing.x3, Spacing.x4, Spacing.x4),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                            const Size(0, Sizes.secondaryHeight),
                        padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.x5),
                      ),
                      child: const Text('Reset'),
                    ),
                    const SizedBox(width: Spacing.x3),
                    Expanded(
                      child: FilledButton(
                        onPressed: _apply,
                        child: Text(
                          count == null
                              ? 'Show cars'
                              : 'Show $count cars',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.x3),
      child: Text(label,
          style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

// ── Toggle row (Switch) ──────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
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
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: BrandColors.primary, size: Sizes.icon),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodyLarge),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ── Theme FilterChip group ───────────────────────────────────────────────────

/// Uses the theme's [ChipThemeData] — selected = primary, unselected = surface2.
class _ChipGroup extends StatelessWidget {
  final Map<String, String> options;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _ChipGroup({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.x2,
      runSpacing: Spacing.x2,
      children: options.entries.map((e) {
        final isSel = selected == e.key;
        return FilterChip(
          label: Text(
            e.value,
            // Force readable contrast: near-black on the lime selected fill.
            style: TextStyle(
              color:
                  isSel ? BrandColors.primaryFg : BrandColors.foreground,
              fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          selected: isSel,
          onSelected: (_) => onSelect(isSel ? null : e.key),
          showCheckmark: false,
        );
      }).toList(),
    );
  }
}
