import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../app/theme_mode_provider.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../auth/domain/providers/auth_provider.dart';

/// Settings screen — spec §7.40.
///
/// Grouped sections: Account · App · Privacy · About
/// Surface cards, chevron rows, lime Switches.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late Map<String, bool> _channels;
  late String _language;
  bool _saving = false;

  static const _languages = {
    'en': 'English',
    'es': 'Español',
    'ar': 'العربية',
    'fr': 'Français',
    'de': 'Deutsch',
  };

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    final settings = user?.notificationSettings ?? const {};
    _channels = {
      'bookings': settings['bookings'] != false,
      'messages': settings['messages'] != false,
      'promotions': settings['promotions'] != false,
    };
    _language = user?.preferredLanguage ?? 'en';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(authProvider.notifier).updateProfile({
        'preferred_language': _language,
        'notification_settings': _channels,
      });
      if (mounted) AppSnack.success(context, 'Settings saved.');
    } catch (_) {
      if (mounted) AppSnack.error(context, 'Could not save settings.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickLanguage() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: Spacing.x4),
            Text('Language', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: Spacing.x2),
            ..._languages.entries.map((e) => ListTile(
                  title: Text(e.value),
                  trailing: e.key == _language
                      ? Icon(Icons.check, color: BrandColors.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, e.key),
                )),
            const SizedBox(height: Spacing.x4),
          ],
        ),
      ),
    );
    if (picked != null && picked != _language) {
      setState(() => _language = picked);
      await _save();
    }
  }

  void _soon() => AppSnack.soon(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x6),
          children: [
            // Header
            Row(
              children: [
                _BackButton(),
                const SizedBox(width: Spacing.x4),
                Text('Settings',
                    style: Theme.of(context).textTheme.headlineMedium),
                const Spacer(),
                if (_saving)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.x6),
            // § Account
            _section('ACCOUNT', [
              _RowTile(
                icon: Icons.person_outline,
                label: 'Personal info',
                onTap: () => context.push('/profile/personal'),
              ),
              _RowTile(
                icon: Icons.lock_outline,
                label: 'Change password',
                onTap: _soon,
              ),
              _RowTile(
                icon: Icons.shield_outlined,
                label: 'Linked accounts',
                onTap: _soon,
              ),
            ]),
            const SizedBox(height: Spacing.x5),
            // § App
            _section('APP', [
              _ToggleRow(
                icon: Icons.notifications_none,
                label: 'Push notifications',
                value: _channels['bookings']!,
                onChanged: (v) {
                  setState(() {
                    _channels['bookings'] = v;
                    _channels['messages'] = v;
                    _channels['promotions'] = v;
                  });
                  _save();
                },
              ),
              _RowTile(
                icon: Icons.language,
                label: 'Language',
                value: _languages[_language] ?? 'English',
                onTap: _pickLanguage,
              ),
              _RowTile(
                icon: Icons.attach_money,
                label: 'Currency',
                value: 'AED',
                onTap: _soon,
              ),
              _ToggleRow(
                icon: Icons.dark_mode_outlined,
                label: 'Dark mode',
                value: Theme.of(context).brightness == Brightness.dark,
                onChanged: (v) =>
                    ref.read(themeModeProvider.notifier).setDark(v),
              ),
            ]),
            const SizedBox(height: Spacing.x5),
            // § Privacy
            _section('PRIVACY', [
              _RowTile(
                icon: Icons.security_outlined,
                label: 'Privacy & security',
                onTap: _soon,
              ),
              _RowTile(
                icon: Icons.data_usage_outlined,
                label: 'Data & permissions',
                onTap: _soon,
              ),
            ]),
            const SizedBox(height: Spacing.x5),
            // § About
            _section('ABOUT', [
              _RowTile(
                icon: Icons.help_outline,
                label: 'Help center',
                onTap: _soon,
              ),
              _RowTile(
                icon: Icons.description_outlined,
                label: 'Terms & policies',
                onTap: _soon,
              ),
              _RowTile(
                icon: Icons.info_outline,
                label: 'About Drivly',
                onTap: _soon,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
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
              for (var i = 0; i < rows.length; i++) ...[
                rows[i],
                if (i != rows.length - 1)
                  Divider(
                      height: 1, indent: 60, color: BrandColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Row tile (chevron) ───────────────────────────────────────────────────────

class _RowTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _RowTile({
    required this.icon,
    required this.label,
    this.value,
    required this.onTap,
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
              child: Icon(icon, color: BrandColors.primary, size: Sizes.icon),
            ),
            const SizedBox(width: Spacing.x3),
            Expanded(
              child:
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
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

// ─── Toggle row ───────────────────────────────────────────────────────────────

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

// ─── Back button ──────────────────────────────────────────────────────────────

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
          child:
              Icon(Icons.arrow_back, color: BrandColors.foreground, size: 20),
        ),
      ),
    );
  }
}
