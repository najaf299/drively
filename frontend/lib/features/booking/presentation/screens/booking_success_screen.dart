import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/booking.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/auth/domain/providers/auth_provider.dart';
import '../../../../shared/widgets/glow_background.dart';

/// Post-payment confirmation — spec §7.15.
///
/// Big success check 96 px in primary wrapped with BrandShadows.glow.
/// Title displaySmall 'Booking confirmed'. Booking ID in BrandText.mono.
/// PrimaryButton 'View trip'. Tonal 'Add to wallet pass' / 'Back to home'.
class BookingSuccessScreen extends ConsumerWidget {
  final Booking booking;
  const BookingSuccessScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(authProvider).user?.email;
    final carName = booking.car?.displayName ?? 'car';
    final t = Theme.of(context).textTheme;

    final dateRange = (booking.pickupAt != null && booking.returnAt != null)
        ? '${Formatters.dayMonth(booking.pickupAt!)} – '
            '${Formatters.date(booking.returnAt!)}'
        : 'your selected dates';

    final pickup = booking.pickupAt != null
        ? Formatters.dateTime(booking.pickupAt!)
        : 'See trip details';
    final location =
        booking.pickupAddress ?? booking.car?.address ?? 'See trip details';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: BrandColors.background,
        // Same branded top-glow backdrop as the splash / auth screens.
        body: GlowBackground(
          glowAlignment: const Alignment(0, -1.1),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.x6),
              child: Column(
                children: [
                  const Spacer(),

                  // ── Glow check — spec §7.15 primary + BrandShadows.glow ─────
                  const _GlowCheck(),
                  const SizedBox(height: Spacing.x6),

                  // ── Title — displaySmall ─────────────────────────────────────
                  Text(
                    'Booking confirmed',
                    textAlign: TextAlign.center,
                    style: t.displaySmall,
                  ),
                  const SizedBox(height: Spacing.x3),
                  Text(
                    'Your $carName is booked for $dateRange.'
                    '${email != null ? ' Confirmation sent to $email.' : ''}',
                    textAlign: TextAlign.center,
                    style: t.bodyLarge?.copyWith(color: BrandColors.mutedFg),
                  ),
                  const SizedBox(height: Spacing.x6),

                  // ── Details card with mono booking ID ────────────────────────
                  _detailsCard(context, pickup: pickup, location: location),
                  const Spacer(),

                  // ── CTAs ─────────────────────────────────────────────────────
                  FilledButton(
                    onPressed: () => context.go('/trips'),
                    child: const Text('View trip'),
                  ),
                  const SizedBox(height: Spacing.x3),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Add to wallet pass'),
                  ),
                  const SizedBox(height: Spacing.x3),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Back to home'),
                  ),
                  const SizedBox(height: Spacing.x4),
                ],
              ),
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
          const SizedBox(height: Spacing.x2),
          // Booking ID in BrandText.mono — spec §7.15.
          Text(
            booking.reference.toUpperCase(),
            style: BrandText.mono(size: 22, spacing: 3),
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

/// Lime circle ~96 px with check icon, wrapped in BrandShadows.glow.
/// Spec §7.15.
class _GlowCheck extends StatelessWidget {
  const _GlowCheck();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: BrandShadows.glow,
      ),
      child: Container(
        width: 96,
        height: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: BrandColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          size: 52,
          color: BrandColors.primaryFg,
        ),
      ),
    );
  }
}
