import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Branded splash shown while the session is restored on launch. Navigation
/// away from here is driven by the router's auth redirect.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: BrandColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_car_rounded,
                  size: 48, color: BrandColors.primaryFg),
            ),
            const SizedBox(height: Spacing.x5),
            Text(
              'drivly',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: BrandColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: Spacing.x8),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
