import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Dark auth/onboarding background with a soft light-glow bleeding in from the
/// top (the signature look from the Drivly brand screens). Layers a radial
/// glow over the near-black scaffold, then renders [child] on top.
class GlowBackground extends StatelessWidget {
  final Widget child;

  /// Where the glow originates. Defaults to the upper-right, matching the
  /// welcome screen; pass `Alignment(0, -1.2)` for a centred top glow.
  final Alignment glowAlignment;

  /// Glow tint. Defaults to the brand glow ([BrandColors.heroGlow]).
  final Color? glowColor;

  /// Glow strength (0–1).
  final double intensity;

  const GlowBackground({
    super.key,
    required this.child,
    this.glowAlignment = const Alignment(0.65, -1.15),
    this.glowColor,
    this.intensity = 0.55,
  });

  @override
  Widget build(BuildContext context) {
    final glow = glowColor ?? BrandColors.heroGlow;
    return ColoredBox(
      color: BrandColors.background,
      child: Stack(
        children: [
          // Primary top glow.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: glowAlignment,
                  radius: 1.15,
                  colors: [
                    glow.withValues(alpha: intensity),
                    glow.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          // Faint secondary glow on the opposite top edge for depth.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.9, -1.2),
                  radius: 0.9,
                  colors: [
                    glow.withValues(alpha: intensity * 0.3),
                    glow.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.8],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// The Drivly wordmark used on auth screens — lowercase "drivly" with the
/// signature lime accent dot (matches the brand reference). The dot is drawn
/// as a real glowing lime circle (not a text period) so it always reads as a
/// clear green dot, at any size, regardless of font loading.
class DrivlyWordmark extends StatelessWidget {
  final double size;
  final bool showDot;
  const DrivlyWordmark({super.key, this.size = 28, this.showDot = true});

  @override
  Widget build(BuildContext context) {
    final dot = size * 0.17;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'drivly',
          style: BrandText.display(
            size: size,
            weight: FontWeight.w700,
            color: BrandColors.foreground,
            spacing: -0.5,
          ),
        ),
        if (showDot)
          Padding(
            // Lift the dot off the descender line so it sits like a period,
            // with a small gap after the wordmark.
            padding: EdgeInsets.only(left: size * 0.05, bottom: size * 0.13),
            child: Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                color: BrandColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: BrandColors.primary.withValues(alpha: 0.55),
                    blurRadius: size * 0.22,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
