import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/car.dart';
import '../../core/utils/formatters.dart';
import 'app_network_image.dart';
import 'status_chip.dart';

/// Standard car listing card used on Home, Search and Favourites.
///
/// Layout: a 16:10 cover image with a category pill (top-left) and a heart
/// favourite button in a dark circle (top-right); below, the car name and a
/// lime price, then a rating row and a location.
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

  static String _label(String s) {
    if (s.isEmpty) return s;
    return s
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.xl),
        boxShadow: BrandShadows.card,
      ),
      child: Material(
        color: BrandColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
          side: const BorderSide(color: BrandColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Hero(
                    tag: 'car-${car.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(Radii.xl),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: AppNetworkImage(
                          url: car.coverPhotoUrl,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                  // Category pill (or host status) over the image, top-left.
                  Positioned(
                    top: Spacing.x3,
                    left: Spacing.x3,
                    child: showStatus
                        ? StatusChip.car(car.status)
                        : _CategoryPill(label: _label(car.fuelType)),
                  ),
                  // Favourite heart in a dark circle, top-right.
                  if (onToggleFavorite != null)
                    Positioned(
                      top: Spacing.x3,
                      right: Spacing.x3,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onToggleFavorite,
                          child: SizedBox(
                            width: Sizes.avatarSm,
                            height: Sizes.avatarSm,
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                              color: isFavorite
                                  ? BrandColors.accent
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(Spacing.x4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            car.displayName,
                            style: text.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: Spacing.x2),
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
                              TextSpan(
                                text: '/day',
                                style: text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.x2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 16, color: BrandColors.warning),
                        const SizedBox(width: 3),
                        Text(
                          car.averageRating.toStringAsFixed(1),
                          style: text.titleSmall,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '· ${car.totalReviews} trips',
                          style: text.bodySmall,
                        ),
                        const Spacer(),
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: BrandColors.mutedFg),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            car.distance != null
                                ? Formatters.distance(car.distance!)
                                : car.city,
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall,
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
      ),
    );
  }
}

/// Small dark-glass category pill rendered over a car cover image.
class _CategoryPill extends StatelessWidget {
  final String label;
  const _CategoryPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
