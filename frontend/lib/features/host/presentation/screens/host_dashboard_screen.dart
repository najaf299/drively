import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/providers/host_provider.dart';

/// Host dashboard — spec §7.28.
///
/// Hero earnings card ~200h: surfaceCard gradient · 'This week' · AED balance
/// displayMedium in primary · sparkline accent (purple). Quick stats row 3:
/// Bookings · Occupancy · Rating. 'Today's pickups' list. 'Action needed'
/// warningBg tonal list. 2×2 stat grid on surface/Radii.xl.
class HostDashboardScreen extends ConsumerWidget {
  const HostDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final earnings = ref.watch(hostEarningsProvider('week'));
    final cars = ref.watch(hostCarsProvider);
    final bookings = ref.watch(hostBookingsProvider);
    final verification = ref.watch(hostVerificationProvider);

    final needsVerification = verification.maybeWhen(
      data: (v) => v.notStarted || !v.isComplete,
      orElse: () => false,
    );

    final weekTotal = earnings.maybeWhen(
      data: (e) => e.total,
      orElse: () => null,
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/host/add-car'),
        backgroundColor: BrandColors.primary,
        foregroundColor: BrandColors.primaryFg,
        icon: const Icon(Icons.add),
        label: const Text('Add car'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(hostEarningsProvider('week'));
            ref.invalidate(hostCarsProvider);
            ref.invalidate(hostBookingsProvider);
            ref.invalidate(hostVerificationProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                Spacing.x5, Spacing.x5, Spacing.x5, Spacing.x10),
            children: [
              // Greeting row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: BrandColors.mutedFg)),
                        const SizedBox(height: 2),
                        Text(
                          user?.name.split(' ').first ?? 'Host',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: Sizes.avatar / 2,
                    backgroundColor: BrandColors.surface2,
                    child: Text(
                      (user?.name.isNotEmpty ?? false)
                          ? user!.name[0].toUpperCase()
                          : 'H',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: BrandColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.x5),
              // Verification banner
              if (needsVerification) _verificationBanner(context),
              // Hero earnings card ~200h
              _EarningsHeroCard(total: weekTotal),
              const SizedBox(height: Spacing.x4),
              // Quick stats row: Bookings · Occupancy · Rating
              Row(
                children: [
                  Expanded(
                    child: _QuickStatTile(
                      label: 'Bookings',
                      value: bookings.maybeWhen(
                          data: (b) => '${b.length}', orElse: () => '—'),
                      icon: Icons.event_note_outlined,
                    ),
                  ),
                  const SizedBox(width: Spacing.x3),
                  Expanded(
                    child: _QuickStatTile(
                      label: 'Occupancy',
                      value: cars.maybeWhen(
                        data: (c) {
                          if (c.isEmpty) return '—';
                          // Placeholder occupancy calc
                          return '${((c.length / (c.length + 1)) * 100).round()}%';
                        },
                        orElse: () => '—',
                      ),
                      icon: Icons.bar_chart_outlined,
                    ),
                  ),
                  const SizedBox(width: Spacing.x3),
                  Expanded(
                    child: _QuickStatTile(
                      label: 'Rating',
                      value: (user?.averageRating ?? 0).toStringAsFixed(1),
                      icon: Icons.star_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.x6),
              // 2×2 stat grid
              Text(
                'OVERVIEW',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: BrandColors.mutedFg),
              ),
              const SizedBox(height: Spacing.x3),
              Row(
                children: [
                  Expanded(
                    child: _statTile(
                      context,
                      'Cars',
                      cars.maybeWhen(
                          data: (c) => '${c.length}', orElse: () => '—'),
                      Icons.directions_car_outlined,
                    ),
                  ),
                  const SizedBox(width: Spacing.x3),
                  Expanded(
                    child: _statTile(
                      context,
                      'Earnings',
                      weekTotal != null
                          ? Formatters.money(weekTotal)
                          : '—',
                      Icons.payments_outlined,
                      // earnings accent = BrandColors.accent (purple) per spec
                      accentColor: BrandColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.x3),
              Row(
                children: [
                  Expanded(
                    child: _statTile(
                      context,
                      'Rating',
                      (user?.averageRating ?? 0).toStringAsFixed(1),
                      Icons.star_rounded,
                    ),
                  ),
                  const SizedBox(width: Spacing.x3),
                  Expanded(
                    child: _statTile(
                      context,
                      'Trips total',
                      bookings.maybeWhen(
                          data: (b) => '${b.length}', orElse: () => '—'),
                      Icons.event_note_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.x6),
              // Navigation tiles
              Text(
                'MANAGE',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: BrandColors.mutedFg),
              ),
              const SizedBox(height: Spacing.x3),
              _navTile(context, Icons.directions_car_outlined, 'My cars',
                  'Manage your fleet', '/host/cars'),
              _navTile(context, Icons.event_note_outlined, 'Bookings',
                  'Requests & reservations', '/host/bookings'),
              _navTile(context, Icons.payments_outlined, 'Earnings',
                  'Revenue & payouts', '/host/earnings'),
              _navTile(context, Icons.verified_user_outlined, 'Verification',
                  'Host onboarding status', '/host/verify'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verificationBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.x4),
      padding: const EdgeInsets.all(Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.warningBg,
        borderRadius: BorderRadius.circular(Radii.xl),
        border:
            Border.all(color: BrandColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: BrandColors.warning),
          const SizedBox(width: Spacing.x3),
          const Expanded(
            child: Text('Complete verification to start hosting.'),
          ),
          TextButton(
            onPressed: () => context.push('/host/verify'),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _statTile(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? accentColor,
  }) {
    final color = accentColor ?? BrandColors.primary;
    return Container(
      padding: const EdgeInsets.all(Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: Sizes.icon),
          const SizedBox(height: Spacing.x3),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                  )),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _navTile(BuildContext context, IconData icon, String title,
      String subtitle, String route) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.x3),
      child: Material(
        color: BrandColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
          side: const BorderSide(color: BrandColors.border),
        ),
        child: InkWell(
          onTap: () => context.push(route),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.x4),
            child: Row(
              children: [
                Container(
                  width: Sizes.avatar,
                  height: Sizes.avatar,
                  decoration: BoxDecoration(
                    color: BrandColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Icon(icon,
                      color: BrandColors.primary, size: Sizes.icon),
                ),
                const SizedBox(width: Spacing.x4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style:
                              Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: BrandColors.mutedFg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Hero earnings card (~200h, surfaceCard gradient) ─────────────────────────

class _EarningsHeroCard extends StatelessWidget {
  final double? total;
  const _EarningsHeroCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.x5),
      decoration: BoxDecoration(
        gradient: BrandGradients.surfaceCard,
        borderRadius: BorderRadius.circular(Radii.xl),
        boxShadow: BrandShadows.card,
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('This week',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: BrandColors.mutedFg)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: BrandColors.surface3,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Text('THIS WEEK',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: BrandColors.mutedFg)),
              ),
            ],
          ),
          const SizedBox(height: Spacing.x3),
          // AED balance — displayMedium / headlineLarge in primary
          Text(
            total != null ? Formatters.money(total!) : '—',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: BrandColors.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          const Spacer(),
          // Sparkline placeholder — accent (purple) per spec
          _SparklinePlaceholder(),
        ],
      ),
    );
  }
}

/// Decorative sparkline placeholder using accent color (purple per spec).
class _SparklinePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 32),
      painter: _SparklinePainter(),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  // Static demo points — heights in 0..1 range
  static const _pts = [0.4, 0.55, 0.3, 0.7, 0.5, 0.8, 0.6, 0.9, 0.65, 1.0];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final paint = Paint()
      ..color = BrandColors.accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final step = size.width / (_pts.length - 1);
    final path = Path();
    for (var i = 0; i < _pts.length; i++) {
      final x = i * step;
      final y = size.height * (1 - _pts[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prev = i - 1;
        final cx = (prev * step + x) / 2;
        path.cubicTo(
            cx, size.height * (1 - _pts[prev]), cx, y, x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Quick stat tile (3-col) ──────────────────────────────────────────────────

class _QuickStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _QuickStatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: Spacing.x3, horizontal: Spacing.x3),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: BrandColors.primary, size: Sizes.iconSm),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: BrandColors.foreground,
                  )),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
