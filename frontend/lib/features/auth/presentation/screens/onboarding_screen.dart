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
                  const Text(
                    'drivly',
                    style: TextStyle(
                      color: BrandColors.foreground,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
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
                    style: textTheme.headlineLarge?.copyWith(
                      fontSize: 46,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: Spacing.x5),
                  const Text(
                    'Skip the rental counter. Unlock thousands of cars '
                    'from real owners with your phone.',
                    style: TextStyle(
                      color: BrandColors.mutedFg,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  // Primary CTA -> registration.
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(58),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () => _finish(context, '/register'),
                      child: const Text('Get Started'),
                    ),
                  ),
                  const SizedBox(height: Spacing.x5),
                  Center(
                    child: GestureDetector(
                      onTap: () => _finish(context, '/login'),
                      child: const Text.rich(
                        TextSpan(
                          text: 'Already have an account?  ',
                          style: TextStyle(color: BrandColors.mutedFg),
                          children: [
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
