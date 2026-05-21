import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// A small pill describing a status, coloured by semantic meaning.
///
/// Updated to use tonal background pairs from the v2 token set instead of
/// opacity-derived colours.  The public factory API is unchanged.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color? bgColor;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.bgColor,
  });

  // ---------- Booking --------------------------------------------------------
  factory StatusChip.booking(String status) {
    final s = status.toLowerCase();
    final (Color fg, Color bg) = switch (s) {
      'confirmed' => (BrandColors.primary, BrandColors.surface2),
      'active' => (BrandColors.success, BrandColors.successBg),
      'completed' => (BrandColors.mutedFg, BrandColors.surface2),
      'cancelled' || 'declined' => (
          BrandColors.destructive,
          BrandColors.destructiveBg
        ),
      'pending' => (BrandColors.warning, BrandColors.warningBg),
      _ => (BrandColors.mutedFg, BrandColors.surface2),
    };
    return StatusChip(label: _humanise(status), color: fg, bgColor: bg);
  }

  // ---------- Trip -----------------------------------------------------------
  factory StatusChip.trip(String status) {
    final s = status.toLowerCase();
    final (Color fg, Color bg) = switch (s) {
      'in_progress' => (BrandColors.success, BrandColors.successBg),
      'overdue' => (BrandColors.destructive, BrandColors.destructiveBg),
      'completed' => (BrandColors.mutedFg, BrandColors.surface2),
      _ => (BrandColors.warning, BrandColors.warningBg),
    };
    return StatusChip(label: _humanise(status), color: fg, bgColor: bg);
  }

  // ---------- Car listing ----------------------------------------------------
  factory StatusChip.car(String status) {
    final s = status.toLowerCase();
    final (Color fg, Color bg) = switch (s) {
      'active' => (BrandColors.success, BrandColors.successBg),
      'pending_approval' => (BrandColors.warning, BrandColors.warningBg),
      'rejected' || 'suspended' => (
          BrandColors.destructive,
          BrandColors.destructiveBg
        ),
      'draft' || _ => (BrandColors.mutedFg, BrandColors.surface2),
    };
    return StatusChip(label: _humanise(status), color: fg, bgColor: bg);
  }

  // ---------- Verification ---------------------------------------------------
  factory StatusChip.verification(String status) {
    final s = status.toLowerCase();
    final (Color fg, Color bg) = switch (s) {
      'approved' => (BrandColors.success, BrandColors.successBg),
      'submitted' || 'in_review' => (BrandColors.warning, BrandColors.warningBg),
      'rejected' => (BrandColors.destructive, BrandColors.destructiveBg),
      _ => (BrandColors.mutedFg, BrandColors.surface2),
    };
    return StatusChip(label: _humanise(status), color: fg, bgColor: bg);
  }

  static String _humanise(String s) {
    if (s.isEmpty) return s;
    return s
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final bg = bgColor ?? BrandColors.surface2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}
