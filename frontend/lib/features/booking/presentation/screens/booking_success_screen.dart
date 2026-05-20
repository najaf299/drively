import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/booking.dart';
import '../../../../core/utils/formatters.dart';

/// Post-payment confirmation screen.
class BookingSuccessScreen extends StatelessWidget {
  final Booking booking;
  const BookingSuccessScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.x6),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: BrandColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 72, color: BrandColors.primary),
              ),
              const SizedBox(height: Spacing.x6),
              Text('You\'re all set!', style: text.headlineLarge),
              const SizedBox(height: Spacing.x2),
              Text(
                'Confirmation #${booking.reference}',
                style: const TextStyle(
                  color: BrandColors.mutedFg,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: Spacing.x6),
              Container(
                padding: const EdgeInsets.all(Spacing.x4),
                decoration: BoxDecoration(
                  color: BrandColors.surface,
                  borderRadius: BorderRadius.circular(Radii.card),
                  border: Border.all(color: BrandColors.border),
                ),
                child: Column(
                  children: [
                    _row('Car', booking.car?.displayNameWithYear ?? 'Your car'),
                    if (booking.pickupAt != null)
                      _row('Pickup', Formatters.dateTime(booking.pickupAt!)),
                    if (booking.returnAt != null)
                      _row('Return', Formatters.dateTime(booking.returnAt!)),
                    _row(
                        'Total', Formatters.money(booking.pricing.totalAmount)),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/trips'),
                  child: const Text('View my trips'),
                ),
              ),
              const SizedBox(height: Spacing.x2),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: BrandColors.mutedFg)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
