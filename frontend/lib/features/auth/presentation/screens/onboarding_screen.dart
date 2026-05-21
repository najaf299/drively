import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/storage/local_cache.dart';

/// First-launch welcome screen. Sets `onboarding_done` so returning users skip
/// straight to sign-in (handled by the router redirect).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _PageData(
      icon: Icons.directions_car_rounded,
      title: 'Any car,\nanywhere.',
      body: 'Skip the rental counter. Unlock thousands of cars '
          'from real owners with just your phone.',
    ),
    _PageData(
      icon: Icons.my_location_rounded,
      title: 'Find rides\nnear you.',
      body: 'Browse verified vehicles close to you and book in '
          'seconds — no queues, no paperwork.',
    ),
    _PageData(
      icon: Icons.shield_outlined,
      title: 'Drive with\nconfidence.',
      body: 'Every trip is insured and every host is verified so '
          'you can hit the road without a second thought.',
    ),
  ];

  Future<void> _finish(String route) async {
    await LocalCache.setBool('onboarding_done', true);
    if (mounted) context.go(route);
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish('/register');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // Hero gradient background.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: BrandGradients.hero),
            ),
          ),
          // Subtle accent radial glow at the top (use BrandColors.accent token).
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -1.1),
                  radius: 1.1,
                  colors: [
                    BrandColors.accent.withValues(alpha: 0.18),
                    BrandColors.background.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar: spacer + Skip ghost link top-right.
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.x5, vertical: Spacing.x3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _finish('/login'),
                        child: Text(
                          'Skip',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: BrandColors.mutedFg),
                        ),
                      ),
                    ],
                  ),
                ),
                // PageView — hero illustration ~60% of remaining height.
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, index) =>
                        _OnboardingPage(data: _pages[index]),
                  ),
                ),
                // Bottom section: dots + CTA.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.x5, Spacing.x5, Spacing.x5, Spacing.x6),
                  child: Column(
                    children: [
                      _PageDots(count: _pages.length, active: _page),
                      const SizedBox(height: Spacing.x6),
                      // CTA wrapped in glow — radius must be Radii.pill.
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Radii.pill),
                          boxShadow: BrandShadows.glow,
                        ),
                        child: FilledButton(
                          onPressed: _next,
                          child: Text(isLast ? 'Get started' : 'Next'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page data model.
// ---------------------------------------------------------------------------

class _PageData {
  final IconData icon;
  final String title;
  final String body;
  const _PageData({
    required this.icon,
    required this.title,
    required this.body,
  });
}

// ---------------------------------------------------------------------------
// Single onboarding page: hero illustration ~60%, then title + body.
// ---------------------------------------------------------------------------

class _OnboardingPage extends StatelessWidget {
  final _PageData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero illustration — ~60% of remaining column height.
          Expanded(
            flex: 6,
            child: Center(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: BrandColors.surface,
                  borderRadius: BorderRadius.circular(Radii.xl),
                  border: Border.all(
                    color: BrandColors.border,
                  ),
                ),
                child: Center(
                  child: Icon(
                    data.icon,
                    size: 96,
                    color: BrandColors.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.x6),
          // Title — displayMedium (h2 / 26px).
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: textTheme.displayMedium,
                ),
                const SizedBox(height: Spacing.x3),
                Text(
                  data.body,
                  style: textTheme.bodyLarge
                      ?.copyWith(color: BrandColors.mutedFg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page dots: active = primary 24×8 pill, inactive = border/subtleFg 8×8.
// ---------------------------------------------------------------------------

class _PageDots extends StatelessWidget {
  final int count;
  final int active;
  const _PageDots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.x1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 24 : 8,
            height: 8,
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
