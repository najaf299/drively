import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/storage/local_cache.dart';

/// First-launch welcome screen. Sets `onboarding_done` so returning users skip
/// straight to sign-in (handled by the router redirect).
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _finish(BuildContext context, String route) async {
    await LocalCache.setBool('onboarding_done', true);
    if (context.mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Stack(
        children: [
          // Subtle blue radial glow at the top.
          const Positioned.fill(child: _TopGlow()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.x6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Spacing.x4),
                  // Wordmark.
                  Text(
                    'drivly',
                    style: textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  // Three-line hero headline; "Anytime." in the lime accent.
                  Text.rich(
                    const TextSpan(
                      children: [
                        TextSpan(text: 'Any car.\n'),
                        TextSpan(text: 'Anywhere.\n'),
                        TextSpan(
                          text: 'Anytime.',
                          style: TextStyle(color: BrandColors.primary),
                        ),
                      ],
                    ),
                    style: textTheme.displayMedium,
                  ),
                  const SizedBox(height: Spacing.x5),
                  Text(
                    'Skip the rental counter. Unlock thousands of cars '
                    'from real owners with your phone.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: BrandColors.mutedFg,
                    ),
                  ),
                  const SizedBox(height: Spacing.x6),
                  const _PageIndicator(active: 0),
                  const Spacer(),
                  // Primary CTA -> registration with a soft lime halo.
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Radii.xxl),
                      boxShadow: BrandShadows.glow,
                    ),
                    child: FilledButton(
                      onPressed: () => _finish(context, '/register'),
                      child: const Text('Get Started'),
                    ),
                  ),
                  const SizedBox(height: Spacing.x5),
                  Center(
                    child: GestureDetector(
                      onTap: () => _finish(context, '/login'),
                      child: Text.rich(
                        TextSpan(
                          text: 'Already have an account?  ',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: BrandColors.mutedFg),
                          children: const [
                            TextSpan(
                              text: 'Sign in',
                              style: TextStyle(
                                color: BrandColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.x4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three rounded page-indicator pills; the active one is a wide lime bar.
class _PageIndicator extends StatelessWidget {
  final int active;
  const _PageIndicator({required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final isActive = i == active;
        return Padding(
          padding: const EdgeInsets.only(right: Spacing.x2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: isActive ? 24 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? BrandColors.primary : BrandColors.border,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
        );
      }),
    );
  }
}

/// A soft blue radial glow anchored to the top of the screen.
class _TopGlow extends StatelessWidget {
  const _TopGlow();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -1.1),
          radius: 1.1,
          colors: [
            const Color(0xFF3B5BDB).withValues(alpha: 0.28),
            BrandColors.background.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.7],
        ),
      ),
    );
  }
}
