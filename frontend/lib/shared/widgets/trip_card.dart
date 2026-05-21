import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/booking.dart';
import '../../core/utils/formatters.dart';
import 'app_network_image.dart';

/// Compact booking/trip row used on My Trips and Host Bookings.
///
/// When [featured] is true the card is rendered as a lime-gradient hero with
/// dark text (used for the next/upcoming trip on the Trips screen).
class TripCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool featured;

  const TripCard({
    super.key,
    required this.booking,
    this.onTap,
    this.trailing,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    return featured ? _featured(context) : _standard(context);
  }

  // ---- Standard dark row ---------------------------------------------------
  Widget _standard(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final car = booking.car;
    final host = car?.host?.name;
    return Material(
      color: BrandColors.surface,
      borderRadius: BorderRadius.circular(Radii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.card),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.x3),
          child: Row(
            children: [
              AppNetworkImage(
                url: car?.coverPhotoUrl,
                width: 64,
                height: 64,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              const SizedBox(width: Spacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car?.displayNameWithYear ?? booking.reference,
                      style: text.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(host),
                      style: text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (trailing != null) ...[
                      const SizedBox(height: Spacing.x2),
                      trailing!,
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Spacing.x2),
              const Icon(Icons.chevron_right,
                  color: BrandColors.mutedFg, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Featured lime hero --------------------------------------------------
  Widget _featured(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final car = booking.car;
    final location = booking.pickupAddress ?? car?.city;
    const radius = Radii.card + 4.0;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: BrandGradients.primary,
          ),
          padding: const EdgeInsets.all(Spacing.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppNetworkImage(
                    url: car?.coverPhotoUrl,
                    width: 68,
                    height: 68,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  const SizedBox(width: Spacing.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Tag(label: 'NEXT'),
                        const SizedBox(height: 6),
                        Text(
                          car?.displayNameWithYear ?? booking.reference,
                          style: text.titleLarge
                              ?.copyWith(color: BrandColors.primaryFg),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _pickupLine(),
                          style: text.bodySmall?.copyWith(
                            color: BrandColors.primaryFg.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (location != null && location.isNotEmpty) ...[
                const SizedBox(height: Spacing.x3),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.x3, vertical: 6),
                  decoration: BoxDecoration(
                    color: BrandColors.primaryFg.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: BrandColors.primaryFg),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: BrandColors.primaryFg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(String? host) {
    final dates = (booking.pickupAt != null && booking.returnAt != null)
        ? '${Formatters.dayMonth(booking.pickupAt!)} → '
            '${Formatters.dayMonth(booking.returnAt!)}'
        : booking.reference;
    if (host != null && host.isNotEmpty) return '$dates · Host: $host';
    return dates;
  }

  String _pickupLine() {
    final pickup = booking.pickupAt;
    if (pickup == null) return 'Upcoming trip';
    final diff = pickup.difference(DateTime.now());
    if (diff.isNegative) return 'Pickup ready';
    if (diff.inDays >= 1) {
      final hours = diff.inHours % 24;
      return 'Pickup in ${Formatters.plural(diff.inDays, 'day')} · ${hours}h';
    }
    if (diff.inHours >= 1) {
      final mins = diff.inMinutes % 60;
      return 'Pickup in ${diff.inHours}h ${mins}m';
    }
    return 'Pickup in ${diff.inMinutes}m';
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: BrandColors.primaryFg,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: BrandColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

