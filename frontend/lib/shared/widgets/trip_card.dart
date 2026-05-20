import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/booking.dart';
import '../../core/utils/formatters.dart';
import 'app_network_image.dart';
import 'status_chip.dart';

/// Compact booking/trip row used on My Trips and Host Bookings.
class TripCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;
  final Widget? trailing;

  const TripCard({super.key, required this.booking, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final car = booking.car;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.card),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.x3),
          child: Row(
            children: [
              AppNetworkImage(
                url: car?.coverPhotoUrl,
                width: 84,
                height: 84,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              const SizedBox(width: Spacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            car?.displayNameWithYear ?? booking.reference,
                            style: text.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusChip.booking(booking.status),
                      ],
                    ),
                    const SizedBox(height: Spacing.x1),
                    Text(
                      booking.reference,
                      style: const TextStyle(
                        color: BrandColors.mutedFg,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: Spacing.x2),
                    if (booking.pickupAt != null && booking.returnAt != null)
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 13, color: BrandColors.mutedFg),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${Formatters.dayMonth(booking.pickupAt!)} → '
                              '${Formatters.dayMonth(booking.returnAt!)}',
                              style: const TextStyle(
                                color: BrandColors.mutedFg,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            Formatters.money(booking.pricing.totalAmount),
                            style: text.titleSmall?.copyWith(
                              color: BrandColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    if (trailing != null) ...[
                      const SizedBox(height: Spacing.x3),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
