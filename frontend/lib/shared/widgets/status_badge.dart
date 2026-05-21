import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Tonal status badge — drivly Flutter Build Spec v2 §2.11.
///
/// Pill height ~24, horizontal padding 10, label 11 w700 UPPERCASE.
/// Tonal background + matching foreground.  Live maps to the destructive tonal
/// (no purple gradient per spec: accent is promo/premium ONLY).
enum BadgeTone {
  success,
  warning,
  error,
  neutral,
  live,

  // Alias so callers that pass BadgeTone.destructive keep working.
  destructive,

  // Info variant.
  info,
}

/// Pill-shaped tonal status badge with optional leading icon.
class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;
  final IconData? icon;

  const StatusBadge(
    this.label, {
    super.key,
    this.tone = BadgeTone.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // live and destructive both map to destructive tonal.
    final resolved = (tone == BadgeTone.live || tone == BadgeTone.destructive)
        ? BadgeTone.error
        : tone;

    final (Color fg, Color bg) = switch (resolved) {
      BadgeTone.success => (BrandColors.success, BrandColors.successBg),
      BadgeTone.warning => (BrandColors.warning, BrandColors.warningBg),
      BadgeTone.error => (BrandColors.destructive, BrandColors.destructiveBg),
      BadgeTone.info => (BrandColors.info, BrandColors.surface2),
      BadgeTone.neutral || _ => (BrandColors.mutedFg, BrandColors.surface2),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }
}

/// Back-compat alias — some screens import BadgePill directly.
typedef BadgePill = StatusBadge;
