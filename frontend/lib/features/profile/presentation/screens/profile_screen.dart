import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/user.dart';
import '../../../../shared/widgets/app_avatar.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
          title: const Text('Profile'), automaticallyImplyLeading: false),
      body: ListView(
        children: [
          const SizedBox(height: Spacing.x4),
          Center(
            child: AppAvatar(
              imageUrl: user.avatarUrl,
              initials: user.initials,
              radius: 44,
            ),
          ),
          const SizedBox(height: Spacing.x3),
          Center(
            child: Text(user.name,
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          Center(
            child: Text(user.email,
                style: const TextStyle(color: BrandColors.mutedFg)),
          ),
          const SizedBox(height: Spacing.x4),
          _verificationBadges(user),
          const SizedBox(height: Spacing.x4),
          _statsRow(user),
          const SizedBox(height: Spacing.x5),
          _group('Account', [
            _tile(context, Icons.badge_outlined, 'Driver\'s licence',
                () => context.push('/kyc'),
                trailing: _kycChip(user.kycStatus)),
            _tile(context, Icons.account_balance_wallet_outlined, 'Wallet',
                () => context.go('/wallet')),
            _tile(context, Icons.credit_card_outlined, 'Payment methods',
                () => context.push('/payment-methods')),
          ]),
          _group('Hosting', [
            if (user.isHost)
              _tile(context, Icons.dashboard_outlined, 'Host dashboard',
                  () => context.push('/host'))
            else
              _tile(context, Icons.add_business_outlined, 'Become a host',
                  () => context.push('/host/verify')),
          ]),
          _group('General', [
            _tile(context, Icons.notifications_none, 'Notifications',
                () => context.push('/notifications')),
            _tile(context, Icons.settings_outlined, 'Settings',
                () => context.push('/settings')),
          ]),
          Padding(
            padding: const EdgeInsets.all(Spacing.x5),
            child: OutlinedButton.icon(
              onPressed: () => _signOut(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: BrandColors.destructive,
                side: const BorderSide(color: BrandColors.destructive),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verificationBadges(User user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _badge('Email', user.isEmailVerified),
        const SizedBox(width: Spacing.x3),
        _badge('Phone', user.isPhoneVerified),
        const SizedBox(width: Spacing.x3),
        _badge('Licence', user.isKycApproved),
      ],
    );
  }

  Widget _badge(String label, bool verified) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          verified ? Icons.verified : Icons.error_outline,
          size: 16,
          color: verified ? BrandColors.success : BrandColors.warning,
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: BrandColors.mutedFg, fontSize: 12)),
      ],
    );
  }

  Widget _statsRow(User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.x5),
      child: Row(
        children: [
          _stat('${user.totalTrips}', 'Trips'),
          _stat(user.averageRating.toStringAsFixed(1), 'Rating'),
          _stat(user.role[0].toUpperCase() + user.role.substring(1), 'Role'),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: Spacing.x3),
        decoration: BoxDecoration(
          color: BrandColors.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: BrandColors.border),
        ),
        child: Column(
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(label,
                style:
                    const TextStyle(color: BrandColors.mutedFg, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _group(String title, List<Widget> tiles) {
    if (tiles.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x2),
          child: Text(title,
              style: const TextStyle(
                  color: BrandColors.mutedFg, fontWeight: FontWeight.w600)),
        ),
        ...tiles,
      ],
    );
  }

  Widget _tile(
      BuildContext context, IconData icon, String label, VoidCallback onTap,
      {Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: BrandColors.foreground),
      title: Text(label),
      trailing: trailing ??
          const Icon(Icons.chevron_right, color: BrandColors.mutedFg),
      onTap: onTap,
    );
  }

  Widget _kycChip(String status) {
    final approved = status == 'approved';
    return Text(
      approved ? 'Verified' : 'Verify',
      style: TextStyle(
        color: approved ? BrandColors.success : BrandColors.warning,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
