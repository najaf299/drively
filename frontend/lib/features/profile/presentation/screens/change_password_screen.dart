import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../auth/domain/providers/auth_provider.dart';

/// Change-password screen (Settings › Account › Change password).
///
/// Verifies the current password server-side, sets a new one and keeps the
/// current session signed in (other devices are revoked by the backend).
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNext = true;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await ref.read(authProvider.notifier).changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (!mounted) return;
      AppSnack.success(context, 'Password updated.');
      context.pop();
    } on AppException catch (e) {
      if (mounted) AppSnack.error(context, e.message);
    } catch (_) {
      if (mounted) AppSnack.error(context, 'Could not update password.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final strength = Validators.passwordStrength(_next.text);

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x6),
            children: [
              Row(
                children: [
                  const SettingsBackButton(),
                  const SizedBox(width: Spacing.x4),
                  Text('Change password', style: text.headlineMedium),
                ],
              ),
              const SizedBox(height: Spacing.x3),
              Text(
                'For your security, enter your current password before '
                'choosing a new one.',
                style: text.bodyMedium?.copyWith(color: BrandColors.mutedFg),
              ),
              const SizedBox(height: Spacing.x6),
              TextFormField(
                controller: _current,
                obscureText: _obscureCurrent,
                autofillHints: const [AutofillHints.password],
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter your current password' : null,
                decoration: InputDecoration(
                  labelText: 'Current password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.x4),
              TextFormField(
                controller: _next,
                obscureText: _obscureNext,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.password,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'New password',
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureNext ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscureNext = !_obscureNext),
                  ),
                ),
              ),
              if (_next.text.isNotEmpty) ...[
                const SizedBox(height: Spacing.x3),
                _StrengthMeter(score: strength),
              ],
              const SizedBox(height: Spacing.x4),
              TextFormField(
                controller: _confirm,
                obscureText: _obscureNext,
                validator: Validators.confirmPassword(_next.text),
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: Spacing.x8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: BrandColors.primaryFg,
                          ),
                        )
                      : const Text('Update password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 4-segment password strength meter (matches the sign-up strength cue).
class _StrengthMeter extends StatelessWidget {
  final int score; // 0..4
  const _StrengthMeter({required this.score});

  @override
  Widget build(BuildContext context) {
    const labels = ['Too weak', 'Weak', 'Fair', 'Good', 'Strong'];
    final color = score <= 1
        ? BrandColors.destructive
        : score == 2
            ? BrandColors.warning
            : BrandColors.primary;
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i < score ? color : BrandColors.surface3,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
            ),
          ),
          if (i != 3) const SizedBox(width: 6),
        ],
        const SizedBox(width: Spacing.x3),
        Text(
          labels[score],
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: BrandColors.mutedFg),
        ),
      ],
    );
  }
}

/// Shared circular back button used across the account/settings sub-screens.
class SettingsBackButton extends StatelessWidget {
  const SettingsBackButton({super.key});

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
          child: Icon(Icons.arrow_back, color: BrandColors.foreground, size: 20),
        ),
      ),
    );
  }
}
