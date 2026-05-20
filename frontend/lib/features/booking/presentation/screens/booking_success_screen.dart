import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/booking.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/auth/domain/providers/auth_provider.dart';
import '../../../../shared/widgets/loading_button.dart';

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
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: Spacing.x3),
                Text(
                  'Your $carName is booked for $dateRange.'
                  '${email != null ? ' We sent a confirmation to $email.' : ''}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: BrandColors.mutedFg,
                  ),
                ),
                const SizedBox(height: Spacing.x6),
                _detailsCard(pickup: pickup, location: location),
                const Spacer(),
                _PillButtonTheme(
                  child: LoadingButton(
                    label: 'View trip details',
                    onPressed: () => context.go('/trips'),
                  ),
                ),
                const SizedBox(height: Spacing.x2),
                TextButton(
                  onPressed: () => context.go('/home'),
                  style: TextButton.styleFrom(
                    foregroundColor: BrandColors.mutedFg,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('Back to home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailsCard({required String pickup, required String location}) {
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
          const Text(
            'BOOKING ID',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: BrandColors.mutedFg,
            ),
          ),
          const SizedBox(height: Spacing.x1),
          Text(
            booking.reference,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: BrandColors.foreground,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const Divider(color: BrandColors.border, height: Spacing.x6),
          _row('Pickup', pickup),
          const SizedBox(height: Spacing.x3),
          _row('Location', location),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: BrandColors.mutedFg),
        ),
        const SizedBox(width: Spacing.x4),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: BrandColors.foreground,
            ),
          ),
        ),
      ],
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
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: BrandColors.primary,
          boxShadow: [
            BoxShadow(
              color: BrandColors.primary.withValues(alpha: 0.4),
              blurRadius: 32,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 56,
          color: BrandColors.primaryFg,
        ),
      ),
    );
  }
}
