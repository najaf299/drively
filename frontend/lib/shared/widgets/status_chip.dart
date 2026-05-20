import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// A small pill describing a status, coloured by semantic meaning.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  /// Booking statuses → colour.
  factory StatusChip.booking(String status) {
    final s = status.toLowerCase();
    final color = switch (s) {
      'confirmed' => BrandColors.primary,
      'active' => BrandColors.success,
      'completed' => BrandColors.mutedFg,
      'cancelled' || 'declined' => BrandColors.destructive,
      'pending' => BrandColors.warning,
      _ => BrandColors.mutedFg,
    };
    return StatusChip(label: _humanise(status), color: color);
  }

  /// Trip statuses → colour.
  factory StatusChip.trip(String status) {
    final s = status.toLowerCase();
    final color = switch (s) {
      'in_progress' => BrandColors.success,
      'overdue' => BrandColors.destructive,
      'completed' => BrandColors.mutedFg,
      _ => BrandColors.warning,
    };
    return StatusChip(label: _humanise(status), color: color);
  }

  /// Car listing statuses → colour.
  factory StatusChip.car(String status) {
    final s = status.toLowerCase();
    final color = switch (s) {
      'active' => BrandColors.success,
      'pending_approval' => BrandColors.warning,
      'rejected' || 'suspended' => BrandColors.destructive,
      'draft' => BrandColors.mutedFg,
      _ => BrandColors.mutedFg,
    };
    return StatusChip(label: _humanise(status), color: color);
  }

  /// Verification step statuses → colour.
  factory StatusChip.verification(String status) {
    final s = status.toLowerCase();
    final color = switch (s) {
      'approved' => BrandColors.success,
      'submitted' || 'in_review' => BrandColors.warning,
      'rejected' => BrandColors.destructive,
      _ => BrandColors.mutedFg,
    };
    return StatusChip(label: _humanise(status), color: color);
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
