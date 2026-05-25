import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/booking.dart';
import '../../../../core/models/car.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../../data/booking_service.dart';
import '../../domain/booking_draft.dart';

/// Booking summary / checkout — spec §7.14, §4.2.
///
/// Trip summary card (car thumb 64 + title + dates) · PriceBreakdownRow list
/// (Daily rate × nights, Service fee 12%, Insurance toggle, Promo discount
/// negative in primary, VAT 5%) · Total in headlineMedium primary ·
/// Promo input · Payment method picker · Sticky CTA.
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

  /// Insurance tier selection — Basic / Plus / Max.
  String _insuranceTier = 'basic';

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
    final service = ref.read(bookingServiceProvider);
    try {
      var booking = await service.create(
        carId: widget.draft.car.id,
        pickupAt: widget.draft.pickupAt,
        returnAt: widget.draft.returnAt,
        pickupAddress: widget.draft.car.address,
        addons: _addonPayload.isEmpty ? null : _addonPayload,
        promoCode: _appliedPromo,
      );

      // Create the payment intent on the backend.
      final pay = await service.pay(booking.id);

      // When Stripe is configured, collect the card via the Payment Sheet and
      // confirm; otherwise the backend already settled it in demo mode.
      final clientSecret = pay['client_secret'] as String?;
      final publishableKey = pay['publishable_key'] as String?;
      final isDemo = pay['demo'] == true;

      if (!isDemo &&
          clientSecret != null &&
          publishableKey != null &&
          publishableKey.isNotEmpty) {
        Stripe.publishableKey = publishableKey;
        await Stripe.instance.applySettings();
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Drivly',
            style: ThemeMode.dark,
          ),
        );
        await Stripe.instance.presentPaymentSheet();
        booking = await service.confirmPayment(booking.id);
      }

      if (mounted) context.go('/booking/success', extra: booking);
    } on StripeException catch (e) {
      // User cancelled or the card was declined — stay on checkout.
      if (mounted) {
        AppSnack.error(
            context, e.error.localizedMessage ?? 'Payment was not completed.');
      }
    } on AppException catch (e) {
      if (mounted) AppSnack.error(context, e.message);
    } catch (_) {
      if (mounted) AppSnack.error(context, 'Payment failed. Please try again.');
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
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
                    // §7.14 trip summary card
                    _tripSummaryCard(context, car),
                    const SizedBox(height: Spacing.x4),

                    // Trip info row (dates + location)
                    _infoCard(context, car),
                    const SizedBox(height: Spacing.x4),

                    // Insurance toggle group — Basic / Plus / Max
                    _insuranceCard(context),
                    const SizedBox(height: Spacing.x4),

                    // Other add-ons
                    _addonsCard(context),
                    const SizedBox(height: Spacing.x4),

                    // Promo code input
                    _promoCard(context),
                    const SizedBox(height: Spacing.x4),

                    // Price breakdown
                    _priceCard(context, p, days, car),
                  ],
                ),
              ),
              _bottomBar(context, p),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Spacing.x4, Spacing.x2, Spacing.x5, Spacing.x2),
      child: Row(
        children: [
          _CircleBackButton(onTap: () => context.pop()),
          const SizedBox(width: Spacing.x3),
          Text('Confirm trip',
              style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }

  // ─── Trip summary card ───────────────────────────────────────────────────

  Widget _tripSummaryCard(BuildContext context, Car car) {
    final dateRange =
        '${Formatters.dayMonth(widget.draft.pickupAt)} – '
        '${Formatters.date(widget.draft.returnAt)}';

    return _Surface(
      padding: const EdgeInsets.all(Spacing.x3),
      child: Row(
        children: [
          // Car thumbnail 64 dp
          AppNetworkImage(
            url: car.coverPhotoUrl,
            width: Sizes.avatarLg,
            height: Sizes.avatarLg,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(car.displayNameWithYear,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: Spacing.x1),
                Text(dateRange,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: Spacing.x1),
                Text(
                  Formatters.plural(widget.draft.totalDays, 'day'),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: BrandColors.mutedFg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Info card ───────────────────────────────────────────────────────────

  Widget _infoCard(BuildContext context, Car car) {
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
            context,
            icon: Icons.calendar_today_rounded,
            label: 'Trip dates',
            value: dateRange,
          ),
          const Divider(height: Spacing.x5),
          _infoRow(
            context,
            icon: Icons.place_rounded,
            label: 'Pickup',
            value: pickup.isEmpty ? 'See host for details' : pickup,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context,
      {required IconData icon,
      required String label,
      required String value}) {
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
          child: Icon(icon, size: Sizes.iconSm, color: BrandColors.primary),
        ),
        const SizedBox(width: Spacing.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Insurance toggle group ──────────────────────────────────────────────

  Widget _insuranceCard(BuildContext context) {
    const tiers = ['basic', 'plus', 'max'];
    const labels = ['Basic', 'Plus', 'Max'];

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Insurance', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Spacing.x3),
          Row(
            children: List.generate(tiers.length, (i) {
              final sel = _insuranceTier == tiers[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _insuranceTier = tiers[i]);
                    _fetchPricing();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(right: i < tiers.length - 1 ? Spacing.x2 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel ? BrandColors.primary : BrandColors.surface2,
                      borderRadius: BorderRadius.circular(Radii.sm),
                      border: Border.all(
                        color:
                            sel ? BrandColors.primary : BrandColors.border,
                      ),
                    ),
                    child: Text(
                      labels[i],
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: sel
                                ? BrandColors.primaryFg
                                : BrandColors.foreground,
                          ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Add-ons card ────────────────────────────────────────────────────────

  Widget _addonsCard(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add-ons', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Spacing.x1),
          for (final entry in _addonOptions.entries)
            _AddonTile(
              label: entry.value,
              selected: _addons.contains(entry.key),
              onChanged: (v) {
                setState(() {
                  v ? _addons.add(entry.key) : _addons.remove(entry.key);
                });
                _fetchPricing();
              },
            ),
        ],
      ),
    );
  }

  // ─── Promo card ──────────────────────────────────────────────────────────

  Widget _promoCard(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Promo code', style: Theme.of(context).textTheme.titleLarge),
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
              TextButton(
                onPressed: _applyPromo,
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Price breakdown card ────────────────────────────────────────────────

  Widget _priceCard(
      BuildContext context, BookingPricing? p, int days, Car car) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price breakdown',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Spacing.x3),
          if (_loadingPrice)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Spacing.x4),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (p != null) ...[
            // Daily rate × nights
            _priceRow(
              context,
              '${Formatters.money(p.dailyRate > 0 ? p.dailyRate : car.dailyPrice)}'
              ' × ${Formatters.plural(p.totalDays > 0 ? p.totalDays : days, 'day')}',
              p.subtotal,
            ),
            if (p.serviceFee > 0) ...[
              const Divider(height: Spacing.x4),
              // Service fee 12%
              _priceRow(context, 'Service fee (12%)', p.serviceFee),
            ],
            if (p.addonsTotal > 0) ...[
              const Divider(height: Spacing.x4),
              _priceRow(context, 'Add-ons', p.addonsTotal),
            ],
            if (p.tax > 0) ...[
              const Divider(height: Spacing.x4),
              // VAT 5%
              _priceRow(context, 'VAT (5%)', p.tax),
            ],
            if (p.discount > 0) ...[
              const Divider(height: Spacing.x4),
              // Promo discount — negative value, shown in primary.
              _priceRow(context, 'Promo discount', -p.discount,
                  valueColor: BrandColors.primary),
            ],
            const Divider(height: Spacing.x6),
            // Total — headlineMedium primary.
            _priceRow(context, 'Total', p.totalAmount, total: true),
          ],
        ],
      ),
    );
  }

  Widget _priceRow(BuildContext context, String label, double amount,
      {bool total = false, Color? valueColor}) {
    final t = Theme.of(context).textTheme;
    final labelStyle = total
        ? t.titleMedium
        : t.bodyMedium?.copyWith(color: BrandColors.mutedFg);
    final valueStyle = total
        ? t.headlineMedium?.copyWith(color: BrandColors.primary)
        : t.bodyMedium?.copyWith(
            color: valueColor ?? BrandColors.foreground,
            fontWeight: FontWeight.w500,
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

  // ─── Bottom bar ──────────────────────────────────────────────────────────

  Widget _bottomBar(BuildContext context, BookingPricing? p) {
    final label = p != null
        ? 'Confirm and pay ${Formatters.money(p.totalAmount)}'
        : 'Confirm and pay';
    return Container(
      padding: const EdgeInsets.fromLTRB(
          Spacing.x5, Spacing.x3, Spacing.x5, Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.background,
        border: Border(top: BorderSide(color: BrandColors.border)),
      ),
      child: LoadingButton(
        label: label,
        loading: _confirming,
        onPressed: _loadingPrice ? null : _confirm,
      ),
    );
  }
}

// ─── Shared sub-widgets ──────────────────────────────────────────────────────

/// Circular 40 px back button — surface bg, border.
class _CircleBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.surface,
      shape: CircleBorder(
        side: BorderSide(color: BrandColors.border),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: BrandColors.foreground),
        ),
      ),
    );
  }
}

/// Rounded surface card with subtle border.
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

/// Selectable add-on row with a lime check indicator.
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
                  color:
                      selected ? BrandColors.primary : BrandColors.border,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Icon(Icons.check_rounded,
                      size: 16, color: BrandColors.primaryFg)
                  : null,
            ),
            const SizedBox(width: Spacing.x3),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
