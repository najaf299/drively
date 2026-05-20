import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/user.dart';
import '../../../auth/domain/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (confirm == true) await ref.read(authProvider.notifier).logout();
  }

  void _soon(BuildContext context) =>
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coming soon.')),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x6),
          children: [
            Row(
              children: [
                Text('Profile',
                    style: Theme.of(context).textTheme.headlineLarge),
                const Spacer(),
                _CircleAction(
                  icon: Icons.settings_outlined,
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
            const SizedBox(height: Spacing.x6),
            _ProfileHeader(user: user),
            const SizedBox(height: Spacing.x6),
            _statsRow(user),
            const SizedBox(height: Spacing.x6),
            _MenuCard(
              tiles: [
                _MenuTile(
                  icon: Icons.credit_card_outlined,
                  label: 'Payment methods',
                  onTap: () => context.push('/payment-methods'),
                ),
                _MenuTile(
                  icon: Icons.badge_outlined,
                  label: 'Driver\'s license',
                  onTap: () => context.push('/kyc'),
                  trailing: _kycChip(user.kycStatus),
                ),
                _MenuTile(
                  icon: Icons.history,
                  label: 'Trip history',
                  onTap: () => context.go('/trips'),
                ),
                _MenuTile(
                  icon: Icons.favorite_border,
                  label: 'Favorites',
                  onTap: () => _soon(context),
                ),
                _MenuTile(
                  icon: Icons.notifications_none,
                  label: 'Notifications',
                  onTap: () => context.push('/notifications'),
                ),
                _MenuTile(
                  icon: Icons.help_outline,
                  label: 'Help & support',
                  onTap: () => _soon(context),
                ),
              ],
            ),
            const SizedBox(height: Spacing.x6),
            OutlinedButton.icon(
              onPressed: () => _signOut(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: BrandColors.destructive,
                side: const BorderSide(color: BrandColors.destructive),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsRow(User user) {
    final saved = (user.totalTrips * 23).toDouble();
    return Row(
      children: [
        _stat('${user.totalTrips}', 'Trips'),
        const SizedBox(width: Spacing.x3),
        _stat('${user.totalTrips}', 'Cars rented'),
        const SizedBox(width: Spacing.x3),
        _stat('\$${saved.toStringAsFixed(0)}', 'Saved'),
      ],
    );
  }

  Widget _stat(String value, String label) {
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
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: BrandColors.mutedFg, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _kycChip(String status) {
    final approved = status == 'approved';
    return Text(
      approved ? 'Verified' : 'Verify',
      style: TextStyle(
        color: approved ? BrandColors.success : BrandColors.warning,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final User user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final year = user.createdAt?.year;
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: BrandColors.primary,
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
              ? Image.network(user.avatarUrl!, fit: BoxFit.cover)
              : Center(
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: BrandColors.primaryFg,
                      fontWeight: FontWeight.w700,
                      fontSize: 34,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: Spacing.x4),
        Text(user.name,
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          year != null ? 'Member since $year' : 'Member',
          style: const TextStyle(color: BrandColors.mutedFg, fontSize: 13),
        ),
        const SizedBox(height: Spacing.x3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user.isKycApproved) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.x3, vertical: 5),
                decoration: BoxDecoration(
                  color: BrandColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: BrandColors.primary, size: 14),
                    SizedBox(width: 4),
                    Text('VERIFIED',
                        style: TextStyle(
                          color: BrandColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        )),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.x3),
            ],
            const Icon(Icons.star, color: BrandColors.warning, size: 16),
            const SizedBox(width: 4),
            Text(
              user.averageRating.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<_MenuTile> tiles;
  const _MenuCard({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: BrandColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i != tiles.length - 1)
              const Divider(
                  height: 1, indent: 60, color: BrandColors.border),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.x4, vertical: Spacing.x3),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Icon(icon, color: BrandColors.foreground, size: 22),
            ),
            const SizedBox(width: Spacing.x3),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
            ),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: Spacing.x2),
            ],
            const Icon(Icons.chevron_right, color: BrandColors.mutedFg),
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.surface,
      shape: const CircleBorder(side: BorderSide(color: BrandColors.border)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: BrandColors.foreground, size: 22),
        ),
      ),
    );
  }
}
