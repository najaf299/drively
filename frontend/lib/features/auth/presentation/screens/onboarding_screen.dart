import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/storage/local_cache.dart';

/// First-launch onboarding carousel. Sets `onboarding_done` so returning users
/// skip straight to sign-in (handled by the router redirect).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      icon: Icons.search_rounded,
      title: 'Find your drive',
      subtitle: 'Browse thousands of cars from trusted local hosts, near you.',
    ),
    _Slide(
      icon: Icons.event_available_rounded,
      title: 'Book in seconds',
      subtitle: 'Pick your dates, add insurance and pay securely in-app.',
    ),
    _Slide(
      icon: Icons.vpn_key_rounded,
      title: 'Hit the road',
      subtitle:
          'Message your host, track your trip and rate it when you’re done.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish(String route) async {
    await LocalCache.setBool('onboarding_done', true);
    if (mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _finish('/register'),
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _slides[i],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? BrandColors.primary : BrandColors.surface2,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.x5),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (isLast) {
                          _finish('/register');
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                      child: Text(isLast ? 'Get started' : 'Next'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _finish('/login'),
                    child: const Text('I already have an account'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Slide(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.x6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: BrandColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: BrandColors.border),
            ),
            child: Icon(icon, size: 64, color: BrandColors.primary),
          ),
          const SizedBox(height: Spacing.x8),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: Spacing.x3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: BrandColors.mutedFg, height: 1.4),
          ),
        ],
      ),
    );
  }
}
