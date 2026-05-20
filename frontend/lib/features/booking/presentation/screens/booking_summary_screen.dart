import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/booking.dart';
import '../../../../core/models/car.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../../data/booking_service.dart';
import '../../domain/booking_draft.dart';

/// Review trip, add extras, apply a promo and confirm the booking.
class BookingSummaryScreen extends ConsumerStatefulWidget {
  final BookingDraft draft;
  const BookingSummaryScreen({super.key, required this.draft});

  @override
  ConsumerState<BookingSummaryScreen> createState() =>
      _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends ConsumerState<BookingSummaryScreen> {
  final _promoController = TextEditingController();
  final _addons = <String>{};
  String? _appliedPromo;

  BookingPricing? _pricing;
  bool _loadingPrice = true;
  bool _confirming = false;

  static const _addonOptions = {
    'insurance': 'Full insurance',
    'child_seat': 'Child seat',
    'extra_driver': 'Extra driver',
  };

  @override
  void initState() {
    super.initState();
    _fetchPricing();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _addonPayload =>
      _addons.map((type) => {'type': type}).toList();

  Future<void> _fetchPricing() async {
    setState(() => _loadingPrice = true);
    try {
      final pricing = await ref.read(bookingServiceProvider).pricing(
            carId: widget.draft.car.id,
            pickupAt: widget.draft.pickupAt,
            returnAt: widget.draft.returnAt,
            promoCode: _appliedPromo,
            addons: _addonPayload.isEmpty ? null : _addonPayload,
          );
      if (mounted) setState(() => _pricing = pricing);
    } catch (_) {
      // Fall back to a local estimate if the preview endpoint fails.
      if (mounted) {
        setState(() => _pricing = BookingPricing(
              dailyRate: widget.draft.car.dailyPrice,
              totalDays: widget.draft.totalDays,
              subtotal: widget.draft.car.dailyPrice * widget.draft.totalDays,
              totalAmount: widget.draft.car.dailyPrice * widget.draft.totalDays,
            ));
      }
    } finally {
      if (mounted) setState(() => _loadingPrice = false);
    }
  }

  void _applyPromo() {
    setState(() => _appliedPromo = _promoController.text.trim());
    _fetchPricing();
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    try {
      final booking = await ref.read(bookingServiceProvider).create(
            carId: widget.draft.car.id,
            pickupAt: widget.draft.pickupAt,
            returnAt: widget.draft.returnAt,
            pickupAddress: widget.draft.car.address,
            addons: _addonPayload.isEmpty ? null : _addonPayload,
            promoCode: _appliedPromo,
          );
      if (mounted) context.go('/booking/success', extra: booking);
    } on AppException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.draft.car;
    final p = _pricing;
    final days = widget.draft.totalDays;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: BrandColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.x5, Spacing.x2, Spacing.x5, Spacing.x6),
                  children: [
                    _carCard(car),
                    const SizedBox(height: Spacing.x4),
                    _infoCard(car),
                    const SizedBox(height: Spacing.x4),
                    _addonsCard(),
                    const SizedBox(height: Spacing.x4),
                    _promoCard(),
                    const SizedBox(height: Spacing.x4),
                    _priceCard(p, days, car),
                  ],
                ),
              ),
              _bottomBar(p),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Spacing.x4, Spacing.x2, Spacing.x5, Spacing.x2),
      child: Row(
        children: [
          _CircleBackButton(onTap: () => context.pop()),
          const SizedBox(width: Spacing.x3),
          const Text(
            'Confirm trip',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: BrandColors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _carCard(Car car) {
    final rating = car.averageRating > 0
        ? car.averageRating.toStringAsFixed(1)
        : 'New';
    final subtitle = [
      '${car.year}',
      if (car.trim != null && car.trim!.isNotEmpty) car.trim! else car.model,
    ].join(' · ');

    return _Surface(
      padding: const EdgeInsets.all(Spacing.x3),
      child: Row(
        children: [
          AppNetworkImage(
            url: car.coverPhotoUrl,
            width: 84,
            height: 84,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          const SizedBox(width: Spacing.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  car.displayName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: BrandColors.foreground,
                  ),
                ),
                const SizedBox(height: Spacing.x1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: BrandColors.mutedFg,
                  ),
                ),
                const SizedBox(height: Spacing.x2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: BrandColors.primary),
                    const SizedBox(width: Spacing.x1),
                    Text(
                      rating,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: BrandColors.foreground,
                      ),
                    ),
                    Text(
                      '  ·  ${Formatters.plural(car.totalReviews, 'trip')}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: BrandColors.mutedFg,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(Car car) {
    final dateRange =
        '${Formatters.dayMonth(widget.draft.pickupAt)} – '
        '${Formatters.date(widget.draft.returnAt)}';
    final pickup = car.address.isNotEmpty
        ? car.address
        : [car.city, car.country].where((s) => s.isNotEmpty).join(', ');

    return _Surface(
      child: Column(
        children: [
          _infoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Trip dates',
            value: dateRange,
          ),
          const Divider(color: BrandColors.border, height: Spacing.x5),
          _infoRow(
            icon: Icons.place_rounded,
            label: 'Pickup',
            value: pickup.isEmpty ? 'See host for details' : pickup,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: BrandColors.surface2,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Icon(icon, size: 18, color: BrandColors.primary),
        ),
        const SizedBox(width: Spacing.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: BrandColors.mutedFg,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BrandColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _addonsCard() {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add-ons',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: BrandColors.foreground,
            ),
          ),
          const SizedBox(height: Spacing.x1),
          for (final entry in _addonOptions.entries)
            _AddonTile(
              label: entry.value,
              selected: _addons.contains(entry.key),
              onChanged: (v) {
                setState(() {
                  v
                      ? _addons.add(entry.key)
                      : _addons.remove(entry.key);
                });
                _fetchPricing();
              },
            ),
        ],
      ),
    );
  }

  Widget _promoCard() {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Promo code',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: BrandColors.foreground,
            ),
          ),
          const SizedBox(height: Spacing.x3),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'Enter code',
                    prefixIcon: Icon(Icons.local_offer_outlined),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.x3),
              OutlinedButton(
                onPressed: _applyPromo,
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceCard(BookingPricing? p, int days, Car car) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: BrandColors.foreground,
            ),
          ),
          const SizedBox(height: Spacing.x3),
          if (_loadingPrice)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Spacing.x4),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (p != null) ...[
            _priceRow(
              '${Formatters.money(p.dailyRate > 0 ? p.dailyRate : car.dailyPrice)}'
              ' × ${Formatters.plural(p.totalDays > 0 ? p.totalDays : days, 'day')}',
              p.subtotal,
            ),
            if (p.addonsTotal > 0) _priceRow('Add-ons', p.addonsTotal),
            if (p.serviceFee > 0) _priceRow('Service fee', p.serviceFee),
            if (p.tax > 0) _priceRow('Insurance', p.tax),
            if (p.discount > 0)
              _priceRow('Discount', -p.discount, color: BrandColors.success),
            const Divider(color: BrandColors.border, height: Spacing.x6),
            _priceRow('Total', p.totalAmount, total: true),
          ],
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount,
      {bool total = false, Color? color}) {
    final labelStyle = TextStyle(
      fontSize: total ? 16 : 14,
      fontWeight: total ? FontWeight.w700 : FontWeight.w400,
      color: total ? BrandColors.foreground : BrandColors.mutedFg,
    );
    final valueStyle = TextStyle(
      fontSize: total ? 18 : 14,
      fontWeight: total ? FontWeight.w700 : FontWeight.w500,
      color: color ?? (total ? BrandColors.primary : BrandColors.foreground),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          Text(Formatters.money(amount), style: valueStyle),
        ],
      ),
    );
  }

  Widget _bottomBar(BookingPricing? p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          Spacing.x5, Spacing.x3, Spacing.x5, Spacing.x4),
      decoration: const BoxDecoration(
        color: BrandColors.background,
        border: Border(top: BorderSide(color: BrandColors.border)),
      ),
      child: _PillButtonTheme(
        child: LoadingButton(
          label: p != null
              ? 'Reserve  ·  ${Formatters.money(p.totalAmount)}'
              : 'Reserve',
          loading: _confirming,
          onPressed: _loadingPrice ? null : _confirm,
        ),
      ),
    );
  }
}

/// Wraps a [FilledButton]/[LoadingButton] so it renders as a ~56-tall lime pill.
class _PillButtonTheme extends StatelessWidget {
  final Widget child;
  const _PillButtonTheme({required this.child});

  @override
  Widget build(BuildContext context) {
    return FilledButtonTheme(
      data: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BrandColors.primary,
          foregroundColor: BrandColors.primaryFg,
          disabledBackgroundColor: BrandColors.primary.withValues(alpha: 0.4),
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: const StadiumBorder(),
        ),
      ),
      child: child,
    );
  }
}

/// Circular 40px back button on a surface tile.
class _CircleBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.surface,
      shape: const CircleBorder(
        side: BorderSide(color: BrandColors.border),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: BrandColors.foreground),
        ),
      ),
    );
  }
}

/// A rounded surface card with subtle border, used across the screen.
class _Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _Surface({
    required this.child,
    this.padding = const EdgeInsets.all(Spacing.x4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: BrandColors.border),
      ),
      child: child,
    );
  }
}

/// A selectable add-on row with a lime check indicator.
class _AddonTile extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;
  const _AddonTile({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.md),
      onTap: () => onChanged(!selected),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.x2),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? BrandColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(Radii.sm),
                border: Border.all(
                  color: selected ? BrandColors.primary : BrandColors.border,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: BrandColors.primaryFg)
                  : null,
            ),
            const SizedBox(width: Spacing.x3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: BrandColors.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
