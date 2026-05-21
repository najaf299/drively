import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/car.dart';
import '../../core/utils/formatters.dart';
import 'app_network_image.dart';
import 'status_badge.dart';
import 'status_chip.dart';

/// Standard car listing card — drivly Flutter Build Spec v2 §2.
///
/// Vertical card with a 16:10 cover image (Radii.lg, bottom→top gradient
/// scrim), a favourite heart chip top-right, and a token-styled body section.
class CarCard extends StatelessWidget {
  final Car car;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final bool showStatus; // host fleet view
  final bool instantBook;

  const CarCard({
    super.key,
    required this.car,
    this.onTap,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.showStatus = false,
    this.instantBook = false,
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
        borderRadius: BorderRadius.circular(Radii.lg),
        boxShadow: BrandShadows.card,
      ),
      child: Material(
        color: BrandColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: const BorderSide(color: BrandColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Cover image with scrim + overlay chips ----
              Stack(
                children: [
                  Hero(
                    tag: 'car-${car.id}',
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AppNetworkImage(
                            url: car.coverPhotoUrl,
                            width: double.infinity,
                          ),
                          // Bottom-to-top gradient scrim
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(Radii.lg),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  BrandColors.overlay.withValues(alpha: 0.0),
                                  BrandColors.overlay.withValues(alpha: 0.6),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Category pill / host status — top-left
                  Positioned(
                    top: Spacing.x3,
                    left: Spacing.x3,
                    child: showStatus
                        ? StatusChip.car(car.status)
                        : _CategoryPill(label: _label(car.fuelType)),
                  ),
                  // Favourite heart — top-right, 36px surface chip ~60%
                  if (onToggleFavorite != null)
                    Positioned(
                      top: Spacing.x3,
                      right: Spacing.x3,
                      child: Material(
                        color: BrandColors.surface.withValues(alpha: 0.6),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onToggleFavorite,
                          child: const SizedBox(
                            width: 36,
                            height: 36,
                          ),
                        ),
                      ),
                    ),
                  if (onToggleFavorite != null)
                    Positioned(
                      top: Spacing.x3,
                      right: Spacing.x3,
                      child: IgnorePointer(
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                              color: isFavorite
                                  ? BrandColors.destructive
                                  : BrandColors.foreground,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // ---- Body ----
              Padding(
                padding: const EdgeInsets.all(Spacing.x4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Text(
                      car.displayName,
                      style: text.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Subtitle: Year · Trim
                    Text(
                      '${car.year} · ${_label(car.fuelType)}',
                      style: text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Spacing.x2),
                    // Rating row
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: BrandColors.warning),
                        const SizedBox(width: 3),
                        Text(
                          '${car.averageRating.toStringAsFixed(2)} · '
                          '${car.totalReviews} trips',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.x3),
                    // Footer: price + optional 'Instant book' badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: Formatters.money(car.dailyPrice),
                                style: text.titleMedium
                                    ?.copyWith(color: BrandColors.primary),
                              ),
                              TextSpan(
                                text: '/day',
                                style: text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (instantBook)
                          const StatusBadge(
                            'Instant book',
                            tone: BadgeTone.success,
                            icon: Icons.bolt,
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
        color: BrandColors.overlay.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: BrandColors.foreground,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
