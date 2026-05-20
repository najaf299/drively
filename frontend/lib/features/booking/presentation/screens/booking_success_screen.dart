import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/booking.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/auth/domain/providers/auth_provider.dart';

/// Post-payment confirmation screen.
class BookingSuccessScreen extends ConsumerWidget {
  final Booking booking;
  const BookingSuccessScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(authProvider).user?.email;
    final carName = booking.car?.displayName ?? 'car';

    final dateRange = (booking.pickupAt != null && booking.returnAt != null)
        ? '${Formatters.dayMonth(booking.pickupAt!)} – '
            '${Formatters.date(booking.returnAt!)}'
        : 'your selected dates';

    final pickup = booking.pickupAt != null
        ? Formatters.dateTime(booking.pickupAt!)
        : 'See trip details';
    final location = booking.pickupAddress ??
        booking.car?.address ??
        'See trip details';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: BrandColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.x6),
            child: Column(
              children: [
                const Spacer(),
                const _GlowCheck(),
                const SizedBox(height: Spacing.x6),
                Text(
                  "You're all set!",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: Spacing.x3),
                Text(
                  'Your $carName is booked for $dateRange.'
                  '${email != null ? ' We sent a confirmation to $email.' : ''}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: BrandColors.mutedFg),
                ),
                const SizedBox(height: Spacing.x6),
                _detailsCard(context, pickup: pickup, location: location),
                const Spacer(),
                FilledButton(
                  onPressed: () => context.go('/trips'),
                  child: const Text('View trip details'),
                ),
                const SizedBox(height: Spacing.x3),
                OutlinedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Back to home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailsCard(BuildContext context,
      {required String pickup, required String location}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.x5),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BOOKING ID',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: BrandColors.mutedFg)),
          const SizedBox(height: Spacing.x1),
          Text(
            booking.reference,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          const Divider(height: Spacing.x6),
          _row(context, 'Pickup', pickup),
          const SizedBox(height: Spacing.x3),
          _row(context, 'Location', location),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: BrandColors.mutedFg)),
        const SizedBox(width: Spacing.x4),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleSmall),
        ),
      ],
    );
  }
}

/// A lime circle with a check icon and a soft radial glow behind it.
class _GlowCheck extends StatelessWidget {
  const _GlowCheck();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            BrandColors.primary.withValues(alpha: 0.22),
            BrandColors.primary.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Container(
        width: 96,
        height: 96,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: BrandColors.primary,
          boxShadow: BrandShadows.glow,
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 52,
          color: BrandColors.primaryFg,
        ),
      ),
    );
  }
}
