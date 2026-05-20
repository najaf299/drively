import 'package:flutter/material.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Review & pay')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.x5),
        children: [
          _tripCard(car),
          const SizedBox(height: Spacing.x5),
          Text('Add-ons', style: Theme.of(context).textTheme.titleMedium),
          for (final entry in _addonOptions.entries)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _addons.contains(entry.key),
              title: Text(entry.value),
              onChanged: (v) {
                setState(() {
                  v == true
                      ? _addons.add(entry.key)
                      : _addons.remove(entry.key);
                });
                _fetchPricing();
              },
            ),
          const SizedBox(height: Spacing.x4),
          _promoField(),
          const SizedBox(height: Spacing.x5),
          Text('Price breakdown',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Spacing.x2),
          if (_loadingPrice)
            const Padding(
              padding: EdgeInsets.all(Spacing.x4),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (p != null) ...[
            _priceRow('Subtotal', p.subtotal),
            if (p.addonsTotal > 0) _priceRow('Add-ons', p.addonsTotal),
            if (p.serviceFee > 0) _priceRow('Service fee', p.serviceFee),
            if (p.tax > 0) _priceRow('Tax', p.tax),
            if (p.discount > 0)
              _priceRow('Discount', -p.discount, color: BrandColors.success),
            const Divider(color: BrandColors.border, height: Spacing.x6),
            _priceRow('Total', p.totalAmount, bold: true),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.x4),
          child: LoadingButton(
            label: p != null
                ? 'Confirm & Pay  ·  ${Formatters.money(p.totalAmount)}'
                : 'Confirm & Pay',
            loading: _confirming,
            onPressed: _loadingPrice ? null : _confirm,
          ),
        ),
      ),
    );
  }

  Widget _tripCard(Car car) {
    return Container(
      padding: const EdgeInsets.all(Spacing.x3),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        children: [
          AppNetworkImage(
            url: car.coverPhotoUrl,
            width: 72,
            height: 72,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(car.displayNameWithYear,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: Spacing.x1),
                Text(
                  Formatters.dateTime(widget.draft.pickupAt),
                  style:
                      const TextStyle(color: BrandColors.mutedFg, fontSize: 12),
                ),
                Text(
                  '→ ${Formatters.dateTime(widget.draft.returnAt)}',
                  style:
                      const TextStyle(color: BrandColors.mutedFg, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _promoField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _promoController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Promo code',
              prefixIcon: Icon(Icons.local_offer_outlined),
            ),
          ),
        ),
        const SizedBox(width: Spacing.x3),
        OutlinedButton(onPressed: _applyPromo, child: const Text('Apply')),
      ],
    );
  }

  Widget _priceRow(String label, double amount,
      {bool bold = false, Color? color}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      fontSize: bold ? 16 : 14,
      color: color ?? (bold ? BrandColors.foreground : BrandColors.mutedFg),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(Formatters.money(amount), style: style),
        ],
      ),
    );
  }
}
