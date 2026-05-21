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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Wordmark — Space Grotesk w700 64px in lime (spec §7.1).
              // GoogleFonts.spaceGrotesk is used directly because the ramp tops
              // out at 32px (displayLarge); 64px is only allowed for this one
              // wordmark per the shared theme rules.
              Text(
                'drivly',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  color: BrandColors.primary,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: Spacing.x8),
              // Thin progress indicator anchored below the wordmark.
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: BrandColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
