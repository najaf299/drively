import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import 'change_password_screen.dart';

/// Linked accounts screen (Settings › Account › Linked accounts).
///
/// Shows which sign-in methods are connected to the account (Google, Apple and
/// the email/password used to register). Removing a social connection unlinks
/// it server-side and signs the user out — per the requested UX.
class LinkedAccountsScreen extends ConsumerStatefulWidget {
  const LinkedAccountsScreen({super.key});

  @override
  ConsumerState<LinkedAccountsScreen> createState() =>
      _LinkedAccountsScreenState();
}

class _LinkedAccountsScreenState extends ConsumerState<LinkedAccountsScreen> {
  String? _busyProvider;

  Future<void> _remove(String provider, String label) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Remove $label?',
      message:
          'Disconnecting $label will sign you out of Drivly on this device. '
          'You can reconnect it the next time you sign in.',
      confirmLabel: 'Remove & sign out',
      destructive: true,
    );
    if (!confirm) return;

    setState(() => _busyProvider = provider);
    try {
      // Unlinks server-side, then clears the session (router sends → login).
      await ref.read(authProvider.notifier).unlinkProvider(provider);
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _busyProvider = null);
        AppSnack.error(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busyProvider = null);
        AppSnack.error(context, 'Could not remove that account.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
                const SettingsBackButton(),
                const SizedBox(width: Spacing.x4),
                Text('Linked accounts', style: text.headlineMedium),
              ],
            ),
            const SizedBox(height: Spacing.x3),
            Text(
              'Manage the accounts you use to sign in to Drivly.',
              style: text.bodyMedium?.copyWith(color: BrandColors.mutedFg),
            ),
            const SizedBox(height: Spacing.x6),

            // Email & password — the primary credential, always present.
            _ProviderCard(
              icon: Icons.mail_outline,
              iconColor: BrandColors.primary,
              title: 'Email & password',
              subtitle: user.email,
              connected: true,
              primary: true,
            ),
            const SizedBox(height: Spacing.x3),

            // Google.
            _ProviderCard(
              icon: Icons.g_mobiledata_rounded,
              iconColor: const Color(0xFFEA4335),
              title: 'Google',
              subtitle: user.hasGoogleLinked
                  ? user.email
                  : 'Not connected',
              connected: user.hasGoogleLinked,
              busy: _busyProvider == 'google',
              onRemove: user.hasGoogleLinked
                  ? () => _remove('google', 'Google')
                  : null,
            ),
            const SizedBox(height: Spacing.x3),

            // Apple.
            _ProviderCard(
              icon: Icons.apple,
              iconColor: BrandColors.foreground,
              title: 'Apple',
              subtitle: user.hasAppleLinked ? user.email : 'Not connected',
              connected: user.hasAppleLinked,
              busy: _busyProvider == 'apple',
              onRemove: user.hasAppleLinked
                  ? () => _remove('apple', 'Apple')
                  : null,
            ),

            const SizedBox(height: Spacing.x6),
            Container(
              padding: const EdgeInsets.all(Spacing.x4),
              decoration: BoxDecoration(
                color: BrandColors.surface2,
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(color: BrandColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: BrandColors.mutedFg),
                  const SizedBox(width: Spacing.x3),
                  Expanded(
                    child: Text(
                      'Removing a connection signs you out on this device. '
                      'Your trips, wallet and data stay safe.',
                      style: text.bodySmall
                          ?.copyWith(color: BrandColors.mutedFg, height: 1.4),
                    ),
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

class _ProviderCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool connected;
  final bool primary;
  final bool busy;
  final VoidCallback? onRemove;

  const _ProviderCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.connected,
    this.primary = false,
    this.busy = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Spacing.x4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: Sizes.avatarMd,
            height: Sizes.avatarMd,
            decoration: BoxDecoration(
              color: BrandColors.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: BrandColors.border),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: Spacing.x2),
                    if (connected) _ConnectedPill(),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: BrandColors.mutedFg),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.x2),
          _trailing(context),
        ],
      ),
    );
  }

  Widget _trailing(BuildContext context) {
    if (busy) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (primary) {
      // The base credential can't be removed.
      return Icon(Icons.lock_outline, size: 18, color: BrandColors.subtleFg);
    }
    if (onRemove != null) {
      return TextButton(
        onPressed: onRemove,
        style: TextButton.styleFrom(
          foregroundColor: BrandColors.destructive,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.x3),
          minimumSize: const Size(0, 36),
        ),
        child: const Text('Remove'),
      );
    }
    // Not connected → no client-side OAuth here; surface it as unavailable.
    return Text(
      '—',
      style: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(color: BrandColors.subtleFg),
    );
  }
}

class _ConnectedPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: BrandColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: BrandColors.success.withValues(alpha: 0.4)),
      ),
      child: Text(
        'CONNECTED',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: BrandColors.success,
              fontSize: 9,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
