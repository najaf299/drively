import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/storage/local_cache.dart';
import '../../../../shared/widgets/glow_background.dart';

/// First-launch welcome screen (spec §7.2). Sets `onboarding_done` so returning
/// users skip straight to sign-in (handled by the router redirect). Typographic
/// hero matching the Drivly brand reference: top light-glow, oversized headline
/// with a lime accent word, and a full-pill primary CTA.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _finish(BuildContext context, String route) async {
    await LocalCache.setBool('onboarding_done', true);
    if (context.mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                Spacing.x6, Spacing.x6, Spacing.x6, Spacing.x6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DrivlyWordmark(size: 28),
                const Spacer(flex: 3),
                // Oversized typographic hero — last word in lime.
                Text.rich(
                  TextSpan(
                    style: BrandText.display(size: 52, height: 1.05),
                    children: [
                      const TextSpan(text: 'Any car.\nAnywhere.\n'),
                      TextSpan(
                        text: 'Anytime.',
                        style: BrandText.display(
                          size: 52,
                          height: 1.05,
                          color: BrandColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.x5),
                Text(
                  'Skip the rental counter. Unlock thousands of cars '
                  'from real owners with your phone.',
                  style: text.bodyLarge?.copyWith(
                    color: BrandColors.mutedFg,
                    height: 1.5,
                  ),
                ),
                const Spacer(flex: 4),
                // Primary CTA wrapped in a lime glow halo.
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Radii.pill),
                    boxShadow: BrandShadows.glow,
                  ),
                  child: FilledButton(
                    onPressed: () => _finish(context, '/register'),
                    child: const Text('Get Started'),
                  ),
                ),
                const SizedBox(height: Spacing.x5),
                // Sign-in link.
                Center(
                  child: GestureDetector(
                    onTap: () => _finish(context, '/login'),
                    child: Text.rich(
                      TextSpan(
                        text: 'Already have an account?  ',
                        style: text.bodyMedium
                            ?.copyWith(color: BrandColors.mutedFg),
                        children: [
                          TextSpan(
                            text: 'Sign in',
                            style: text.bodyMedium?.copyWith(
                              color: BrandColors.primaryText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
