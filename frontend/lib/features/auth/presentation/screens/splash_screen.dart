import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme.dart';

/// Branded splash shown while the session is restored on launch. Navigation
/// away from here is driven by the router's auth redirect.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: BrandGradients.hero),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 5),
              // Lime car-icon badge.
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: BrandColors.primary,
                  borderRadius: BorderRadius.circular(Radii.xl),
                  boxShadow: BrandShadows.glow,
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  size: 52,
                  color: BrandColors.primaryFg,
                ),
              ),
              const SizedBox(height: Spacing.x6),
              // Wordmark — Space Grotesk w700 in lime (spec §7.1). Used directly
              // because the type ramp tops out at 32px (displayLarge).
              Text(
                'drivly',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: BrandColors.primary,
                  letterSpacing: -1.5,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: Spacing.x3),
              // Tagline.
              Text(
                'Drive anywhere',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: BrandColors.mutedFg,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(flex: 5),
              // Thin progress indicator anchored above the bottom.
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: BrandColors.primary,
                ),
              ),
              const SizedBox(height: Spacing.x10),
            ],
          ),
        ),
      ),
    );
  }
}
