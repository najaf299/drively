import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../auth/domain/providers/auth_provider.dart';

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
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Settings saved.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not save settings.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        children: [
          _header('Push notifications'),
          ..._channels.keys.map((key) => SwitchListTile(
                title: Text(_channelLabel(key)),
                value: _channels[key]!,
                activeThumbColor: BrandColors.primary,
                onChanged: (v) => setState(() => _channels[key] = v),
              )),
          _header('Language'),
          ..._languages.entries.map((e) => RadioListTile<String>(
                title: Text(e.value),
                value: e.key,
                // ignore: deprecated_member_use
                groupValue: _language,
                // ignore: deprecated_member_use
                onChanged: (v) => setState(() => _language = v ?? 'en'),
              )),
          _header('Appearance'),
          const ListTile(
            title: Text('Theme'),
            subtitle: Text('Dark (default)'),
            trailing: Icon(Icons.dark_mode_outlined),
          ),
        ],
      ),
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(
            Spacing.x5, Spacing.x5, Spacing.x5, Spacing.x2),
        child: Text(text,
            style: const TextStyle(
                color: BrandColors.mutedFg, fontWeight: FontWeight.w600)),
      );

  String _channelLabel(String key) => key[0].toUpperCase() + key.substring(1);
}
