import 'package:flutter/material.dart';

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
              Container(
                width: Sizes.avatarLg + 24,
                height: Sizes.avatarLg + 24,
                decoration: const BoxDecoration(
                  color: BrandColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: BrandShadows.glow,
                ),
                child: const Icon(Icons.directions_car_rounded,
                    size: 48, color: BrandColors.primaryFg),
              ),
              const SizedBox(height: Spacing.x5),
              Text(
                'drivly',
                style: Theme.of(context)
                    .textTheme
                    .displayLarge
                    ?.copyWith(color: BrandColors.primary),
              ),
              const SizedBox(height: Spacing.x8),
              const SizedBox(
                width: Sizes.icon,
                height: Sizes.icon,
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
