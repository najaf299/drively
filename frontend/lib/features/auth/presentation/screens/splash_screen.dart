import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/glow_background.dart';

/// Branded splash shown while the session is restored on launch. Navigation
/// away from here is driven by the router's auth redirect. Uses the same
/// top-glow brand backdrop as the welcome/sign-in screens.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: GlowBackground(
        glowAlignment: Alignment(0, -1.1),
        child: SafeArea(
          child: Column(
            children: [
              Spacer(flex: 5),
              Center(child: DrivlyWordmark(size: 60)),
              Spacer(flex: 5),
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: BrandColors.primary,
                ),
              ),
              SizedBox(height: Spacing.x12),
            ],
          ),
        ),
      ),
    );
  }
}
