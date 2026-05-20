import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Tonal status badge per design system v2 (§2.11).
///
/// Pairs a foreground colour with its tonal background for inline status pills:
/// success / warning / error, plus a gradient `live` variant for hot/active.
enum BadgeTone { success, warning, error, neutral, live }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;
  final IconData? icon;

  const StatusBadge(this.label, {super.key, this.tone = BadgeTone.neutral, this.icon});

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg) = switch (tone) {
      BadgeTone.success => (BrandColors.success, BrandColors.successBg),
      BadgeTone.warning => (BrandColors.warning, BrandColors.warningBg),
      BadgeTone.error => (BrandColors.destructive, BrandColors.destructiveBg),
      BadgeTone.neutral => (BrandColors.mutedFg, BrandColors.surface2),
      BadgeTone.live => (Colors.white, BrandColors.accent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tone == BadgeTone.live ? null : bg,
        gradient: tone == BadgeTone.live ? BrandGradients.accent : null,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: fg, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
