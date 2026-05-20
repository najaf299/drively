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
                        const Text('Welcome back',
                            style: TextStyle(color: BrandColors.mutedFg)),
                        const SizedBox(height: 2),
                        Text(
                          user?.name.split(' ').first ?? 'Host',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: BrandColors.surface2,
                    child: Text(
                      (user?.name.isNotEmpty ?? false)
                          ? user!.name[0].toUpperCase()
                          : 'H',
                      style: const TextStyle(
                          color: BrandColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.x5),
              if (needsVerification) _verificationBanner(context),
              _earningsHero(
                  context,
                  earnings.maybeWhen(
                    data: (e) => e.total,
                    orElse: () => null,
                  )),
              const SizedBox(height: Spacing.x4),
              Row(
                children: [
                  _statCard(
                    'Cars',
                    cars.maybeWhen(
                        data: (c) => '${c.length}', orElse: () => '—'),
                    Icons.directions_car_outlined,
                  ),
                  const SizedBox(width: Spacing.x3),
                  _statCard(
                    'Bookings',
                    bookings.maybeWhen(
                        data: (b) => '${b.length}', orElse: () => '—'),
                    Icons.event_note_outlined,
                  ),
                  const SizedBox(width: Spacing.x3),
                  _statCard(
                    'Rating',
                    (user?.averageRating ?? 0).toStringAsFixed(1),
                    Icons.star_rounded,
                  ),
                ],
              ),
              const SizedBox(height: Spacing.x6),
              const Text(
                'MANAGE',
                style: TextStyle(
                  color: BrandColors.mutedFg,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
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
        color: BrandColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.card),
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
        gradient: const LinearGradient(
          colors: [BrandColors.primary, BrandColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Earnings this month',
                  style: TextStyle(
                      color: BrandColors.primaryFg,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: BrandColors.primaryFg.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: const Text('THIS MONTH',
                    style: TextStyle(
                      color: BrandColors.primaryFg,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    )),
              ),
            ],
          ),
          const SizedBox(height: Spacing.x3),
          Text(
            total != null ? Formatters.money(total) : '—',
            style: const TextStyle(
              color: BrandColors.primaryFg,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: Spacing.x4, horizontal: Spacing.x2),
        decoration: BoxDecoration(
          color: BrandColors.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: BrandColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: BrandColors.primary, size: 22),
            const SizedBox(height: Spacing.x2),
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: BrandColors.primary)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(color: BrandColors.mutedFg, fontSize: 12)),
          ],
        ),
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
          borderRadius: BorderRadius.circular(Radii.card),
          side: const BorderSide(color: BrandColors.border),
        ),
        child: InkWell(
          onTap: () => context.push(route),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.x4),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: BrandColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Icon(icon, color: BrandColors.primary, size: 22),
                ),
                const SizedBox(width: Spacing.x4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              color: BrandColors.mutedFg, fontSize: 12)),
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
