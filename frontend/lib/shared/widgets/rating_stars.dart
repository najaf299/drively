import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Read-only star rating display — drivly Flutter Build Spec v2 §2.
///
/// [RatingStars] shows a single star + optional numeric value (compact).
/// [StarRatingInput] is an interactive 5-star picker.
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showValue;
  final int? reviewCount;

  /// Filled-star colour — defaults to [BrandColors.warning] per spec.
  final Color? fillColor;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.showValue = false,
    this.reviewCount,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded,
            size: size, color: fillColor ?? BrandColors.warning),
        const SizedBox(width: 2),
        if (showValue) ...[
          Text(
            rating.toStringAsFixed(1),
            style: text.bodySmall?.copyWith(
              color: BrandColors.foreground,
              fontWeight: FontWeight.w600,
              fontSize: size * 0.85,
            ),
          ),
        ],
        if (reviewCount != null) ...[
          const SizedBox(width: 2),
          Text(
            '($reviewCount)',
            style: text.bodySmall?.copyWith(fontSize: size * 0.8),
          ),
        ],
      ],
    );
  }
}

/// Interactive 5-star input for rating screens.
class StarRatingInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  /// Fill colour for selected stars — defaults to [BrandColors.warning].
  final Color? fillColor;

  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 40,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = i < value;
        return IconButton(
          onPressed: () => onChanged(i + 1),
          iconSize: size,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          constraints: const BoxConstraints(),
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: filled ? (fillColor ?? BrandColors.warning) : BrandColors.mutedFg,
          ),
        );
      }),
    );
  }
}
