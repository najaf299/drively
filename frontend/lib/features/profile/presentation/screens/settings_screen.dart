import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../app/theme_mode_provider.dart';
import '../../../../shared/widgets/app_dialog.dart' show showConfirmDialog;
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/settings_service.dart';
import '../../domain/providers/settings_provider.dart';

/// Settings screen — drives every preference from the backend Settings
/// endpoint (`/settings`). Local theme override stays in [LocalCache] so the
/// app can paint immediately on cold start, but the canonical value lives in
/// the user's account.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _saving = false;

  static const _languages = {
    'en': 'English',
    'es': 'Español',
    'ar': 'العربية',
    'fr': 'Français',
    'de': 'Deutsch',
  };

  static const _currencies = ['AED', 'USD', 'EUR', 'GBP', 'SAR'];
  static const _units = {'km': 'Kilometres', 'mi': 'Miles'};

  Future<void> _wrap(Future<void> Function() body) async {
    setState(() => _saving = true);
    try {
      await body();
    } catch (e) {
      if (mounted) AppSnack.error(context, 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<T?> _pickFromSheet<T>(
    String title,
    Map<T, String> options,
    T current,
  ) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: BrandColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xxl)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: Spacing.x3),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: BrandColors.borderStrong,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
            ),
            const SizedBox(height: Spacing.x3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.x5),
              child: Row(
                children: [
                  Text(title, style: Theme.of(ctx).textTheme.titleLarge),
                ],
              ),
            ),
            const SizedBox(height: Spacing.x2),
            ...options.entries.map(
              (e) => ListTile(
                title: Text(e.value),
                trailing: e.key == current
                    ? Icon(Icons.check, color: BrandColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, e.key),
              ),
            ),
            const SizedBox(height: Spacing.x4),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOutEverywhere() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Sign out everywhere?',
      message:
          'You will be signed out of this and every other device. You can sign back in any time.',
      confirmLabel: 'Sign out all',
      destructive: true,
    );
    if (!ok) return;
    await _wrap(() async {
      await ref.read(settingsServiceProvider).signOutEverywhere();
      // Drop our local auth too so the next request doesn't 401 silently.
      await ref.read(authProvider.notifier).logout();
    });
  }

  Future<void> _confirmDeleteAccount() async {
    final user = ref.read(authProvider).user;
    // Pure OAuth account = social ID present and no email/password to prove.
    // The backend treats password as optional in that case.
    final fromOauth = user != null &&
        (user.hasGoogleLinked || user.hasAppleLinked) &&
        user.email.isEmpty;
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This soft-deletes your account. Active trips must be ended first. '
              'You will not be able to sign in again with the same email.',
            ),
            if (!fromOauth) ...[
              const SizedBox(height: Spacing.x4),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BrandColors.destructive),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _wrap(() async {
      await ref.read(settingsServiceProvider).deleteAccount(
            password: fromOauth ? null : controller.text,
            fromOauth: fromOauth,
          );
      await ref.read(authProvider.notifier).logout();
    });
  }

  Future<void> _pickThemeMode(String current) async {
    final picked = await _pickFromSheet<String>(
      'Appearance',
      const {'system': 'Match system', 'light': 'Light', 'dark': 'Dark'},
      current,
    );
    if (picked == null || picked == current) return;
    await _wrap(() async {
      await ref.read(settingsProvider.notifier).patch({'theme_mode': picked});
      // Mirror locally so cold start paints in the chosen mode immediately.
      final controller = ref.read(themeModeProvider.notifier);
      switch (picked) {
        case 'light':
          await controller.setDark(false);
        case 'dark':
          await controller.setDark(true);
        case 'system':
          await controller.useSystem();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(settingsProvider);

    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.read(settingsProvider.notifier).refresh(),
          ),
          data: (s) => _Body(
            settings: s,
            saving: _saving,
            onPickLanguage: () async {
              final picked = await _pickFromSheet<String>(
                  'Language', _languages, s.language);
              if (picked != null && picked != s.language) {
                await _wrap(() => ref
                    .read(settingsProvider.notifier)
                    .patch({'preferred_language': picked}));
              }
            },
            onPickCurrency: () async {
              final picked = await _pickFromSheet<String>(
                  'Currency',
                  {for (final c in _currencies) c: c},
                  s.currency);
              if (picked != null && picked != s.currency) {
                await _wrap(() => ref
                    .read(settingsProvider.notifier)
                    .patch({'preferred_currency': picked}));
              }
            },
            onPickUnits: () async {
              final picked =
                  await _pickFromSheet<String>('Units', _units, s.units);
              if (picked != null && picked != s.units) {
                await _wrap(() => ref
                    .read(settingsProvider.notifier)
                    .patch({'preferred_units': picked}));
              }
            },
            onPickTheme: () => _pickThemeMode(s.themeMode),
            onToggleNotification: (channel, key, value) {
              unawaited(_wrap(() => ref
                  .read(settingsProvider.notifier)
                  .toggleNotification(channel, key, value)));
            },
            onTogglePrivacy: (key, value) {
              unawaited(_wrap(() => ref
                  .read(settingsProvider.notifier)
                  .setPrivacy(key, value)));
            },
            onPickLocationPrecision: () async {
              final picked = await _pickFromSheet<String>(
                'Location precision',
                const {'precise': 'Precise', 'approximate': 'Approximate'},
                (s.privacy['location_precision'] as String?) ?? 'precise',
              );
              if (picked != null) {
                await _wrap(() => ref
                    .read(settingsProvider.notifier)
                    .setPrivacy('location_precision', picked));
              }
            },
            onSignOutAll: _confirmSignOutEverywhere,
            onDeleteAccount: _confirmDeleteAccount,
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final AppSettings settings;
  final bool saving;
  final VoidCallback onPickLanguage;
  final VoidCallback onPickCurrency;
  final VoidCallback onPickUnits;
  final VoidCallback onPickTheme;
  final void Function(String channel, String key, bool value)
      onToggleNotification;
  final void Function(String key, dynamic value) onTogglePrivacy;
  final VoidCallback onPickLocationPrecision;
  final VoidCallback onSignOutAll;
  final VoidCallback onDeleteAccount;

  const _Body({
    required this.settings,
    required this.saving,
    required this.onPickLanguage,
    required this.onPickCurrency,
    required this.onPickUnits,
    required this.onPickTheme,
    required this.onToggleNotification,
    required this.onTogglePrivacy,
    required this.onPickLocationPrecision,
    required this.onSignOutAll,
    required this.onDeleteAccount,
  });

  static const _languageLabels = {
    'en': 'English',
    'es': 'Español',
    'ar': 'العربية',
    'fr': 'Français',
    'de': 'Deutsch',
  };
  static const _unitLabels = {'km': 'Kilometres', 'mi': 'Miles'};
  static const _themeLabels = {
    'system': 'Match system',
    'light': 'Light',
    'dark': 'Dark',
  };

  // Per-key fallbacks that mirror the backend defaults
  // (SettingsController::defaultNotificationSettings) so a toggle never renders
  // OFF while the server actually holds it ON (e.g. email.receipts, sms.security).
  static const _emailDefaults = {
    'bookings': true,
    'receipts': true,
    'promotions': false,
  };
  static const _smsDefaults = {'bookings': false, 'security': true};

  bool _push(String key) => settings.notifications['push']?[key] ?? true;
  bool _email(String key) =>
      settings.notifications['email']?[key] ?? (_emailDefaults[key] ?? false);
  bool _sms(String key) =>
      settings.notifications['sms']?[key] ?? (_smsDefaults[key] ?? false);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final priv = settings.privacy;
    final precision = (priv['location_precision'] as String?) ?? 'precise';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x8),
      children: [
        // Header
        Row(
          children: [
            _BackButton(),
            const SizedBox(width: Spacing.x4),
            Text('Settings', style: text.headlineMedium),
            const Spacer(),
            if (saving)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: Spacing.x6),

        // ── Account ────────────────────────────────────────────────
        _Section(title: 'ACCOUNT', children: [
          _RowTile(
            icon: Icons.person_outline,
            label: 'Personal info',
            onTap: () => context.push('/profile/personal'),
          ),
          _RowTile(
            icon: Icons.lock_outline,
            label: 'Change password',
            onTap: () => context.push('/settings/password'),
          ),
          _RowTile(
            icon: Icons.shield_outlined,
            label: 'Linked accounts',
            onTap: () => context.push('/settings/linked'),
          ),
        ]),
        const SizedBox(height: Spacing.x5),

        // ── App ───────────────────────────────────────────────────
        _Section(title: 'APP', children: [
          _RowTile(
            icon: Icons.brightness_6_outlined,
            label: 'Appearance',
            value: _themeLabels[settings.themeMode] ?? settings.themeMode,
            onTap: onPickTheme,
          ),
          _RowTile(
            icon: Icons.language,
            label: 'Language',
            value: _languageLabels[settings.language] ?? settings.language,
            onTap: onPickLanguage,
          ),
          _RowTile(
            icon: Icons.attach_money,
            label: 'Currency',
            value: settings.currency,
            onTap: onPickCurrency,
          ),
          _RowTile(
            icon: Icons.straighten_outlined,
            label: 'Distance units',
            value: _unitLabels[settings.units] ?? settings.units,
            onTap: onPickUnits,
          ),
        ]),
        const SizedBox(height: Spacing.x5),

        // ── Push notifications ────────────────────────────────────
        _Section(title: 'PUSH NOTIFICATIONS', children: [
          _ToggleRow(
            icon: Icons.event_available_outlined,
            label: 'Booking updates',
            value: _push('bookings'),
            onChanged: (v) => onToggleNotification('push', 'bookings', v),
          ),
          _ToggleRow(
            icon: Icons.chat_bubble_outline,
            label: 'Messages',
            value: _push('messages'),
            onChanged: (v) => onToggleNotification('push', 'messages', v),
          ),
          _ToggleRow(
            icon: Icons.local_taxi_outlined,
            label: 'Trip status',
            value: _push('trip_updates'),
            onChanged: (v) =>
                onToggleNotification('push', 'trip_updates', v),
          ),
          _ToggleRow(
            icon: Icons.directions_car_outlined,
            label: 'Host activity',
            value: _push('host_activity'),
            onChanged: (v) =>
                onToggleNotification('push', 'host_activity', v),
          ),
          _ToggleRow(
            icon: Icons.local_offer_outlined,
            label: 'Promotions & offers',
            value: _push('promotions'),
            onChanged: (v) => onToggleNotification('push', 'promotions', v),
          ),
        ]),
        const SizedBox(height: Spacing.x5),

        // ── Email & SMS ───────────────────────────────────────────
        _Section(title: 'EMAIL & SMS', children: [
          _ToggleRow(
            icon: Icons.mail_outline,
            label: 'Email: booking confirmations',
            value: _email('bookings'),
            onChanged: (v) => onToggleNotification('email', 'bookings', v),
          ),
          _ToggleRow(
            icon: Icons.receipt_long_outlined,
            label: 'Email: receipts',
            value: _email('receipts'),
            onChanged: (v) => onToggleNotification('email', 'receipts', v),
          ),
          _ToggleRow(
            icon: Icons.campaign_outlined,
            label: 'Email: promotions',
            value: _email('promotions'),
            onChanged: (v) => onToggleNotification('email', 'promotions', v),
          ),
          _ToggleRow(
            icon: Icons.sms_outlined,
            label: 'SMS: booking alerts',
            value: _sms('bookings'),
            onChanged: (v) => onToggleNotification('sms', 'bookings', v),
          ),
          _ToggleRow(
            icon: Icons.security_outlined,
            label: 'SMS: security alerts',
            value: _sms('security'),
            onChanged: (v) => onToggleNotification('sms', 'security', v),
          ),
        ]),
        const SizedBox(height: Spacing.x5),

        // ── Privacy ───────────────────────────────────────────────
        _Section(title: 'PRIVACY', children: [
          _ToggleRow(
            icon: Icons.visibility_outlined,
            label: 'Share my profile with hosts',
            value: priv['share_profile_with_hosts'] != false,
            onChanged: (v) => onTogglePrivacy('share_profile_with_hosts', v),
          ),
          _ToggleRow(
            icon: Icons.analytics_outlined,
            label: 'Help improve Drivly (analytics)',
            value: priv['analytics_opt_in'] != false,
            onChanged: (v) => onTogglePrivacy('analytics_opt_in', v),
          ),
          _ToggleRow(
            icon: Icons.bug_report_outlined,
            label: 'Crash reports',
            value: priv['crash_reports_opt_in'] != false,
            onChanged: (v) => onTogglePrivacy('crash_reports_opt_in', v),
          ),
          _ToggleRow(
            icon: Icons.campaign_outlined,
            label: 'Personalised marketing',
            value: priv['marketing_opt_in'] == true,
            onChanged: (v) => onTogglePrivacy('marketing_opt_in', v),
          ),
          _RowTile(
            icon: Icons.my_location_outlined,
            label: 'Location precision',
            value:
                precision == 'precise' ? 'Precise' : 'Approximate',
            onTap: onPickLocationPrecision,
          ),
          _RowTile(
            icon: Icons.security_outlined,
            label: 'Privacy & security',
            onTap: () => context.push('/info/security'),
          ),
          _RowTile(
            icon: Icons.data_usage_outlined,
            label: 'Data & permissions',
            onTap: () => context.push('/info/data'),
          ),
        ]),
        const SizedBox(height: Spacing.x5),

        // ── Security ──────────────────────────────────────────────
        _Section(title: 'SECURITY', children: [
          _RowTile(
            icon: Icons.logout,
            label: 'Sign out of all devices',
            onTap: onSignOutAll,
          ),
          _RowTile(
            icon: Icons.delete_outline,
            label: 'Delete account',
            destructive: true,
            onTap: onDeleteAccount,
          ),
        ]),
        const SizedBox(height: Spacing.x5),

        // ── About ─────────────────────────────────────────────────
        _Section(title: 'ABOUT', children: [
          _RowTile(
            icon: Icons.help_outline,
            label: 'Help center',
            onTap: () => context.push('/info/help'),
          ),
          _RowTile(
            icon: Icons.description_outlined,
            label: 'Terms & policies',
            onTap: () => context.push('/info/terms'),
          ),
          _RowTile(
            icon: Icons.info_outline,
            label: 'About Drivly',
            onTap: () => context.push('/info/about'),
          ),
        ]),
        const SizedBox(height: Spacing.x6),
        Center(
          child: Text('Drivly · v1.0.0',
              style: text.bodySmall?.copyWith(color: BrandColors.mutedFg)),
        ),
      ],
    );
  }
}

// ── Section card ────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Spacing.x1, bottom: Spacing.x2),
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: BrandColors.mutedFg),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: BrandColors.surface,
            borderRadius: BorderRadius.circular(Radii.xl),
            border: Border.all(color: BrandColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  Divider(height: 1, indent: 60, color: BrandColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Row tile (chevron) ──────────────────────────────────────────────────────

class _RowTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool destructive;

  const _RowTile({
    required this.icon,
    required this.label,
    this.value,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? BrandColors.destructive : BrandColors.primary;
    final fg = destructive ? BrandColors.destructive : null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.x4, vertical: Spacing.x3),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Icon(icon, color: color, size: Sizes.icon),
            ),
            const SizedBox(width: Spacing.x3),
            Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: fg,
                      )),
            ),
            if (value != null) ...[
              Text(value!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BrandColors.mutedFg,
                      )),
              const SizedBox(width: Spacing.x2),
            ],
            Icon(Icons.chevron_right, color: BrandColors.mutedFg),
          ],
        ),
      ),
    );
  }
}

// ── Toggle row ──────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.x4, vertical: Spacing.x1),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Icon(icon, color: BrandColors.primary, size: Sizes.icon),
          ),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ── Back button ─────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.surface,
      shape: CircleBorder(side: BorderSide(color: BrandColors.border)),
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back,
              color: BrandColors.foreground, size: 20),
        ),
      ),
    );
  }
}
