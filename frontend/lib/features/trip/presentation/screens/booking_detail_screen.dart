import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/booking.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../booking/data/booking_service.dart';
import '../../../booking/domain/providers/booking_provider.dart';
import '../../data/trip_service.dart';

/// Booking detail with status-aware actions (start trip, cancel, rate, report).
class BookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _busy = false;

  Future<void> _startTrip(Booking booking) async {
    setState(() => _busy = true);
    try {
      final trip = await ref.read(tripServiceProvider).start(booking.id);
      if (mounted) unawaited(context.push('/trip/${trip.id}'));
      ref.invalidate(bookingDetailProvider(widget.bookingId));
    } on AppException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(Booking booking) async {
    final reason =
        await _reasonDialog('Cancel booking', 'Reason for cancelling');
    if (reason == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(bookingServiceProvider).cancel(booking.id, reason);
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ref.invalidate(bookingsProvider);
      _snack('Booking cancelled.');
    } on AppException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _callHost(Booking booking) async {
    final phone = booking.car?.host?.phone;
    if (phone == null || phone.isEmpty) {
      _snack('Host phone number is not available.');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _snack('Could not start a call.');
    }
  }

  Future<String?> _reasonDialog(String title, String hint) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(bookingDetailProvider(widget.bookingId));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SafeArea(
          child: AsyncValueView<Booking>(
            value: booking,
            onRetry: () =>
                ref.invalidate(bookingDetailProvider(widget.bookingId)),
            data: (b) => _content(b),
          ),
        ),
      ),
    );
  }

  Widget _content(Booking b) {
    final car = b.car;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Spacing.x5, Spacing.x3, Spacing.x5, Spacing.x4),
          child: Row(
            children: [
              _circleBack(),
              const SizedBox(width: Spacing.x3),
              const Text(
                'Booking',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: BrandColors.foreground,
                ),
              ),
              const Spacer(),
              StatusChip.booking(b.status),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                Spacing.x5, 0, Spacing.x5, Spacing.x5),
            children: [
              Text(
                b.reference,
                style: const TextStyle(
                    color: BrandColors.mutedFg, fontSize: 13),
              ),
              const SizedBox(height: Spacing.x4),
              if (car != null)
                Container(
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: BrandColors.foreground)),
                            const SizedBox(height: 2),
                            Text(car.city,
                                style: const TextStyle(
                                    color: BrandColors.mutedFg, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: Spacing.x4),
              _detailsCard(b),
              const SizedBox(height: Spacing.x4),
              _priceCard(b),
              const SizedBox(height: Spacing.x6),
              ..._actions(b),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailsCard(Booking b) {
    final rows = <Widget>[];
    if (b.pickupAt != null) {
      rows.add(_infoRow(
          Icons.event, 'Pickup', Formatters.dateTime(b.pickupAt!)));
    }
    if (b.returnAt != null) {
      rows.add(_infoRow(Icons.event_available, 'Return',
          Formatters.dateTime(b.returnAt!)));
    }
    if (b.pickupAddress != null) {
      rows.add(_infoRow(
          Icons.location_on_outlined, 'Location', b.pickupAddress!));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.x4, vertical: Spacing.x2),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(children: rows),
    );
  }

  Widget _priceCard(Booking b) {
    return Container(
      padding: const EdgeInsets.all(Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Price',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: BrandColors.foreground)),
          const SizedBox(height: Spacing.x3),
          _priceRow('Subtotal', b.pricing.subtotal),
          if (b.pricing.serviceFee > 0)
            _priceRow('Service fee', b.pricing.serviceFee),
          if (b.pricing.tax > 0) _priceRow('Tax', b.pricing.tax),
          if (b.pricing.discount > 0)
            _priceRow('Discount', -b.pricing.discount),
          const Divider(color: BrandColors.border, height: Spacing.x6),
          _priceRow('Total', b.pricing.totalAmount, bold: true),
        ],
      ),
    );
  }

  Widget _circleBack() {
    return InkWell(
      onTap: () => context.canPop() ? context.pop() : context.go('/trips'),
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: BrandColors.surface,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back,
            size: 20, color: BrandColors.foreground),
      ),
    );
  }

  List<Widget> _actions(Booking b) {
    final widgets = <Widget>[];

    if (b.isActive && b.trip != null) {
      widgets.add(_primaryButton(
        'View live trip',
        icon: Icons.navigation_outlined,
        onPressed: () => context.push('/trip/${b.trip!.id}'),
      ));
    } else if (b.isConfirmed) {
      widgets.add(_primaryButton(
        'Start trip',
        loading: _busy,
        onPressed: _busy ? null : () => _startTrip(b),
      ));
    } else if (b.isCompleted && b.canReview) {
      widgets.add(_primaryButton(
        'Rate your trip',
        icon: Icons.star_outline,
        onPressed: () => context.push('/rate/${b.id}'),
      ));
    }

    if (b.car?.host?.phone != null) {
      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(height: Spacing.x3));
      }
      widgets.add(OutlinedButton.icon(
        onPressed: () => _callHost(b),
        icon: const Icon(Icons.phone_outlined),
        label: const Text('Call host'),
      ));
    }

    if (b.canCancel) {
      widgets.add(const SizedBox(height: Spacing.x2));
      widgets.add(TextButton(
        onPressed: _busy ? null : () => _cancel(b),
        child: const Text('Cancel booking',
            style: TextStyle(color: BrandColors.destructive)),
      ));
    }

    return widgets;
  }

  Widget _primaryButton(
    String label, {
    IconData? icon,
    bool loading = false,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: BrandColors.primaryFg))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(label,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: BrandColors.mutedFg),
          const SizedBox(width: Spacing.x3),
          Text(label, style: const TextStyle(color: BrandColors.mutedFg)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: BrandColors.foreground)),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: bold ? BrandColors.foreground : BrandColors.mutedFg,
      fontSize: bold ? 17 : 14,
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
