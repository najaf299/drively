import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// A hairline divider with rounded (pill) end-caps, inset slightly from the
/// edges so the rounding reads clearly — the rounded counterpart to a plain
/// [Divider], matching the app's rounded-button aesthetic.
///
/// Use in place of `Divider(height: 1, color: BrandColors.border)` and as the
/// top/bottom "line" of bars (nav bar, chat composer, sticky CTAs).
class RoundedDivider extends StatelessWidget {
  /// Line thickness (also the corner radius, giving fully rounded caps).
  final double thickness;

  /// Horizontal inset on each side so the rounded caps sit off the screen edge.
  final double indent;

  /// Line colour. Defaults to [BrandColors.border].
  final Color? color;

  /// Optional total vertical box; the line is centred within it (useful for
  /// giving a divider some breathing room). Null = exactly [thickness] tall.
  final double? height;

  const RoundedDivider({
    super.key,
    this.thickness = 1.5,
    this.indent = 20,
    this.color,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final line = Container(
      height: thickness,
      margin: EdgeInsets.symmetric(horizontal: indent),
      decoration: BoxDecoration(
        color: color ?? BrandColors.border,
        borderRadius: BorderRadius.circular(thickness),
      ),
    );
    if (height == null) return line;
    return SizedBox(height: height, child: Center(child: line));
  }
}
