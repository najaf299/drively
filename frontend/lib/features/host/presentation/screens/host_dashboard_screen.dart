import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/providers/host_provider.dart';

/// Host home: earnings snapshot, quick stats and navigation to fleet, bookings
/// and earnings. Restyled to the Drivly dark premium system.
class HostDashboardScreen extends ConsumerWidget {
  const HostDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final earnings = ref.watch(hostEarningsProvider('month'));
    final cars = ref.watch(hostCarsProvider);
    final bookings = ref.watch(hostBookingsProvider);
    final verification = ref.watch(hostVerificationProvider);

    final needsVerification = verification.maybeWhen(
      data: (v) => v.notStarted || !v.isComplete,
      orElse: () => false,
    );

    final earningsTotal = earnings.maybeWhen(
      data: (e) => e.total,
      orElse: () => null,
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/host/add-car'),
        backgroundColor: BrandColors.primary,
        foregroundColor: BrandColors.primaryFg,
        icon: const Icon(Icons.add),
        label: const Text('Add car',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(hostEarningsProvider('month'));
            ref.invalidate(hostCarsProvider);
            ref.invalidate(hostBookingsProvider);
            ref.invalidate(hostVerificationProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                Spacing.x5, Spacing.x5, Spacing.x5, Spacing.x10),
            children: [
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: BrandColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.x5),
              if (needsVerification) _verificationBanner(context),
              _earningsHero(context, earningsTotal),
              const SizedBox(height: Spacing.x4),
              // 2x2 stat grid.
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
                      'Bookings',
                      bookings.maybeWhen(
                          data: (b) => '${b.length}', orElse: () => '—'),
                      Icons.event_note_outlined,
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
                      'Earnings',
                      earningsTotal != null
                          ? Formatters.money(earningsTotal)
                          : '—',
                      Icons.payments_outlined,
                      accent: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.x6),
              Text(
                'MANAGE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: BrandColors.mutedFg,
                    ),
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
        border: Border.all(color: BrandColors.warning.withValues(alpha: 0.4)),
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

  Widget _earningsHero(BuildContext context, double? total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.x5),
      decoration: BoxDecoration(
        gradient: BrandGradients.primary,
        borderRadius: BorderRadius.circular(Radii.xl),
        boxShadow: BrandShadows.glow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Earnings this month',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: BrandColors.primaryFg,
                      )),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: BrandColors.primaryFg.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Text('THIS MONTH',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: BrandColors.primaryFg,
                        )),
              ),
            ],
          ),
          const SizedBox(height: Spacing.x3),
          Text(
            total != null ? Formatters.money(total) : '—',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: BrandColors.primaryFg,
                ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(
      BuildContext context, String label, String value, IconData icon,
      {bool accent = false}) {
    final color = accent ? BrandColors.accent : BrandColors.primary;
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
                  child:
                      Icon(icon, color: BrandColors.primary, size: Sizes.icon),
                ),
                const SizedBox(width: Spacing.x4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: BrandColors.mutedFg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
