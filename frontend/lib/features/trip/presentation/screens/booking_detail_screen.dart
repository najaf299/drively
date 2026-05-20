import 'dart:async';

import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: AsyncValueView<Booking>(
        value: booking,
        onRetry: () => ref.invalidate(bookingDetailProvider(widget.bookingId)),
        data: (b) => _content(b),
      ),
    );
  }

  Widget _content(Booking b) {
    final car = b.car;
    return ListView(
      padding: const EdgeInsets.all(Spacing.x5),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(b.reference,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            StatusChip.booking(b.status),
          ],
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
                          style: const TextStyle(fontWeight: FontWeight.w600)),
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
        const SizedBox(height: Spacing.x5),
        if (b.pickupAt != null)
          _infoRow(Icons.event, 'Pickup', Formatters.dateTime(b.pickupAt!)),
        if (b.returnAt != null)
          _infoRow(Icons.event_available, 'Return',
              Formatters.dateTime(b.returnAt!)),
        if (b.pickupAddress != null)
          _infoRow(Icons.location_on_outlined, 'Location', b.pickupAddress!),
        const Divider(color: BrandColors.border, height: Spacing.x8),
        Text('Price', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: Spacing.x2),
        _priceRow('Subtotal', b.pricing.subtotal),
        if (b.pricing.serviceFee > 0)
          _priceRow('Service fee', b.pricing.serviceFee),
        if (b.pricing.tax > 0) _priceRow('Tax', b.pricing.tax),
        if (b.pricing.discount > 0) _priceRow('Discount', -b.pricing.discount),
        _priceRow('Total', b.pricing.totalAmount, bold: true),
        const SizedBox(height: Spacing.x8),
        ..._actions(b),
      ],
    );
  }

  List<Widget> _actions(Booking b) {
    final widgets = <Widget>[];

    if (b.car?.host?.phone != null) {
      widgets.add(OutlinedButton.icon(
        onPressed: () => _callHost(b),
        icon: const Icon(Icons.phone_outlined),
        label: const Text('Call host'),
      ));
      widgets.add(const SizedBox(height: Spacing.x3));
    }

    if (b.isActive && b.trip != null) {
      widgets.add(FilledButton.icon(
        onPressed: () => context.push('/trip/${b.trip!.id}'),
        icon: const Icon(Icons.navigation_outlined),
        label: const Text('View live trip'),
      ));
    } else if (b.isConfirmed) {
      widgets.add(FilledButton(
        onPressed: _busy ? null : () => _startTrip(b),
        child: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: BrandColors.primaryFg))
            : const Text('Start trip'),
      ));
    } else if (b.isCompleted && b.canReview) {
      widgets.add(FilledButton.icon(
        onPressed: () => context.push('/rate/${b.id}'),
        icon: const Icon(Icons.star_outline),
        label: const Text('Rate your trip'),
      ));
    }

    if (b.canCancel) {
      widgets.add(const SizedBox(height: Spacing.x3));
      widgets.add(TextButton(
        onPressed: _busy ? null : () => _cancel(b),
        child: const Text('Cancel booking',
            style: TextStyle(color: BrandColors.destructive)),
      ));
    }

    return widgets;
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: BrandColors.mutedFg),
          const SizedBox(width: Spacing.x3),
          Text(label, style: const TextStyle(color: BrandColors.mutedFg)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: bold ? BrandColors.foreground : BrandColors.mutedFg,
      fontSize: bold ? 16 : 14,
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
