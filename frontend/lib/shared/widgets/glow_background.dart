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

  /// Glow tint. Defaults to the cool blue brand glow.
  final Color glowColor;

  /// Glow strength (0–1).
  final double intensity;

  const GlowBackground({
    super.key,
    required this.child,
    this.glowAlignment = const Alignment(0.65, -1.15),
    this.glowColor = BrandColors.heroGlow,
    this.intensity = 0.55,
  });

  @override
  Widget build(BuildContext context) {
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
                    glowColor.withValues(alpha: intensity),
                    glowColor.withValues(alpha: 0.0),
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
                    glowColor.withValues(alpha: intensity * 0.3),
                    glowColor.withValues(alpha: 0.0),
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

/// The Drivly wordmark used on auth screens — lowercase "drivly" with an
/// optional lime period accent (matches the brand reference).
class DrivlyWordmark extends StatelessWidget {
  final double size;
  final bool showDot;
  const DrivlyWordmark({super.key, this.size = 28, this.showDot = true});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: BrandText.display(
          size: size,
          weight: FontWeight.w700,
          color: BrandColors.foreground,
          spacing: -0.5,
        ),
        children: [
          const TextSpan(text: 'drivly'),
          if (showDot)
            TextSpan(
              text: '.',
              style: BrandText.display(
                size: size,
                weight: FontWeight.w700,
                color: BrandColors.primary,
                spacing: -0.5,
              ),
            ),
        ],
      ),
    );
  }
}
