import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/car.dart';
import '../../core/utils/formatters.dart';
import 'app_network_image.dart';
import 'rating_stars.dart';
import 'status_chip.dart';

/// Standard car listing card used on Home, Search and Favourites.
class CarCard extends StatelessWidget {
  final Car car;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final bool showStatus; // host fleet view

  const CarCard({
    super.key,
    required this.car,
    this.onTap,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.showStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'car-${car.id}',
                  child: AppNetworkImage(
                    url: car.coverPhotoUrl,
                    height: 168,
                    width: double.infinity,
                  ),
                ),
                if (showStatus)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: StatusChip.car(car.status),
                  ),
                if (onToggleFavorite != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: const CircleBorder(),
                      child: IconButton(
                        iconSize: 20,
                        onPressed: onToggleFavorite,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite
                              ? BrandColors.destructive
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.x3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          car.displayNameWithYear,
                          style: text.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: Formatters.money(car.dailyPrice),
                              style: text.titleMedium?.copyWith(
                                color: BrandColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(
                              text: '/day',
                              style: TextStyle(
                                color: BrandColors.mutedFg,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.x2),
                  Row(
                    children: [
                      RatingStars(
                        rating: car.averageRating,
                        showValue: true,
                        reviewCount: car.totalReviews,
                        size: 15,
                      ),
                      const SizedBox(width: Spacing.x3),
                      const Icon(Icons.event_seat_outlined,
                          size: 14, color: BrandColors.mutedFg),
                      const SizedBox(width: 2),
                      Text('${car.seats}',
                          style: const TextStyle(
                              color: BrandColors.mutedFg, fontSize: 12)),
                      const Spacer(),
                      if (car.distance != null)
                        Text(
                          Formatters.distance(car.distance!),
                          style: const TextStyle(
                              color: BrandColors.mutedFg, fontSize: 12),
                        )
                      else
                        Flexible(
                          child: Text(
                            car.city,
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: BrandColors.mutedFg, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
