import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/providers/host_provider.dart';

/// Host home: earnings snapshot, quick stats and navigation to fleet, bookings
/// and earnings.
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
      appBar: AppBar(title: const Text('Host')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/host/add-car'),
        icon: const Icon(Icons.add),
        label: const Text('Add car'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(hostEarningsProvider('month'));
          ref.invalidate(hostCarsProvider);
          ref.invalidate(hostBookingsProvider);
          ref.invalidate(hostVerificationProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(Spacing.x5),
          children: [
            Text('Good day, ${user?.name.split(' ').first ?? 'host'}',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: Spacing.x4),
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
                  cars.maybeWhen(data: (c) => '${c.length}', orElse: () => '—'),
                  Icons.directions_car_outlined,
                ),
                const SizedBox(width: Spacing.x3),
                _statCard(
                  'Bookings',
                  bookings.maybeWhen(
                      data: (b) => '${b.length}', orElse: () => '—'),
                  Icons.book_online_outlined,
                ),
                const SizedBox(width: Spacing.x3),
                _statCard(
                  'Rating',
                  (user?.averageRating ?? 0).toStringAsFixed(1),
                  Icons.star_outline,
                ),
              ],
            ),
            const SizedBox(height: Spacing.x6),
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
          const Text('Earnings this month',
              style: TextStyle(color: BrandColors.primaryFg)),
          const SizedBox(height: Spacing.x2),
          Text(
            total != null ? Formatters.money(total) : '—',
            style: const TextStyle(
              color: BrandColors.primaryFg,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Spacing.x3),
        decoration: BoxDecoration(
          color: BrandColors.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: BrandColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: BrandColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(label,
                style:
                    const TextStyle(color: BrandColors.mutedFg, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _navTile(BuildContext context, IconData icon, String title,
      String subtitle, String route) {
    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.x3),
      child: ListTile(
        leading: Icon(icon, color: BrandColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle:
            Text(subtitle, style: const TextStyle(color: BrandColors.mutedFg)),
        trailing: const Icon(Icons.chevron_right, color: BrandColors.mutedFg),
        onTap: () => context.push(route),
      ),
    );
  }
}
