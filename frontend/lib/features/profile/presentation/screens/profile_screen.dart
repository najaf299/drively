import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/user.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/domain/providers/auth_provider.dart';

/// Profile screen — spec §7.26.
///
/// Header: avatar 96 (avatarXl) · name headlineSmall · email muted ·
/// VERIFIED StatusBadge. Stats row: Trips · Reviews · Member since.
/// Settings list grouped in surface cards with chevrons.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actionsPadding: const EdgeInsets.fromLTRB(
            Spacing.x5, Spacing.x2, Spacing.x5, Spacing.x5),
        actions: [
          Row(
            children: [
              // Cancel — tonal, equal width/height.
              Expanded(
                child: SizedBox(
                  height: Sizes.secondaryHeight,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.x3),
              // Sign out — destructive, equal width/height.
              Expanded(
                child: SizedBox(
                  height: Sizes.secondaryHeight,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: BrandColors.destructive,
                      foregroundColor: Colors.white,
                      minimumSize:
                          const Size.fromHeight(Sizes.secondaryHeight),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Sign out'),
                  ),
                ),
              ),
            ],
          ),
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
            // Page title + settings cog
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
            // Header: avatar 96 + name + email + verified badge
            _ProfileHeader(user: user),
            const SizedBox(height: Spacing.x6),
            // Stats row: Trips · Reviews · Member since
            _statsRow(context, user),
            const SizedBox(height: Spacing.x6),
            // Personal group
            _sectionLabel(context, 'ACCOUNT'),
            const SizedBox(height: Spacing.x2),
            _MenuCard(
              tiles: [
                _MenuTile(
                  icon: Icons.person_outline,
                  label: 'Personal info',
                  onTap: () => _soon(context),
                ),
                _MenuTile(
                  icon: Icons.credit_card_outlined,
                  label: 'Payment methods',
                  onTap: () => context.push('/payment-methods'),
                ),
                _MenuTile(
                  icon: Icons.location_on_outlined,
                  label: 'Addresses',
                  onTap: () => _soon(context),
                ),
                _MenuTile(
                  icon: Icons.notifications_none,
                  label: 'Notifications',
                  onTap: () => context.push('/notifications'),
                ),
                _MenuTile(
                  icon: Icons.language,
                  label: 'Language',
                  onTap: () => _soon(context),
                ),
              ],
            ),
            const SizedBox(height: Spacing.x5),
            // Host group
            _sectionLabel(context, 'HOST'),
            const SizedBox(height: Spacing.x2),
            _MenuCard(
              tiles: [
                _MenuTile(
                  icon: Icons.directions_car_outlined,
                  label: 'Become a host',
                  iconColor: BrandColors.primary,
                  labelColor: BrandColors.primary,
                  onTap: () => context.push('/host'),
                ),
              ],
            ),
            const SizedBox(height: Spacing.x5),
            // Support + legal group
            _sectionLabel(context, 'SUPPORT'),
            const SizedBox(height: Spacing.x2),
            _MenuCard(
              tiles: [
                _MenuTile(
                  icon: Icons.help_outline,
                  label: 'Help',
                  onTap: () => _soon(context),
                ),
                _MenuTile(
                  icon: Icons.description_outlined,
                  label: 'Legal',
                  onTap: () => _soon(context),
                ),
              ],
            ),
            const SizedBox(height: Spacing.x5),
            // Logout — destructive
            OutlinedButton.icon(
              onPressed: () => _signOut(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: BrandColors.destructive,
                side: const BorderSide(color: BrandColors.destructive),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context)
          .textTheme
          .labelSmall
          ?.copyWith(color: BrandColors.mutedFg),
    );
  }

  Widget _statsRow(BuildContext context, User user) {
    final memberYear = user.createdAt?.year.toString() ?? '—';
    return Row(
      children: [
        _stat(context, '${user.totalTrips}', 'Trips'),
        const SizedBox(width: Spacing.x3),
        _stat(context,
            user.averageRating > 0
                ? user.averageRating.toStringAsFixed(1)
                : '—',
            'Reviews'),
        const SizedBox(width: Spacing.x3),
        _stat(context, memberYear, 'Member since'),
      ],
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: Spacing.x4, horizontal: Spacing.x2),
        decoration: BoxDecoration(
          color: BrandColors.surface,
          borderRadius: BorderRadius.circular(Radii.xl),
          border: Border.all(color: BrandColors.border),
        ),
        child: Column(
          children: [
            Text(value,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

// ─── Profile header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final User user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar — 96dp = Sizes.avatarXl
        Container(
          width: Sizes.avatarXl,
          height: Sizes.avatarXl,
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
                    style:
                        Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: BrandColors.primaryFg,
                            ),
                  ),
                ),
        ),
        const SizedBox(height: Spacing.x4),
        // Name — headlineSmall
        Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        // Email — muted
        Text(
          user.email,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: BrandColors.mutedFg),
        ),
        const SizedBox(height: Spacing.x3),
        // VERIFIED badge (success) + rating
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user.isKycApproved) ...[
              const StatusBadge('VERIFIED',
                  tone: BadgeTone.success, icon: Icons.verified),
              const SizedBox(width: Spacing.x3),
            ],
            const Icon(Icons.star_rounded,
                color: BrandColors.warning, size: 16),
            const SizedBox(width: 4),
            Text(
              user.averageRating.toStringAsFixed(1),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Menu card + tile ─────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final List<_MenuTile> tiles;
  const _MenuCard({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: BrandColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i != tiles.length - 1)
              const Divider(height: 1, indent: 60, color: BrandColors.border),
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
  final Color? iconColor;
  final Color? labelColor;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
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
              child: Icon(icon,
                  color: iconColor ?? BrandColors.foreground,
                  size: Sizes.icon),
            ),
            const SizedBox(width: Spacing.x3),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: labelColor,
                    ),
              ),
            ),
            Icon(Icons.chevron_right,
                color: labelColor != null
                    ? labelColor!.withValues(alpha: 0.6)
                    : BrandColors.mutedFg),
          ],
        ),
      ),
    );
  }
}

// ─── Circle action button ─────────────────────────────────────────────────────

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
