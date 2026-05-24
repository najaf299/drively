import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/glow_background.dart';
import '../../domain/providers/auth_provider.dart';

/// Two-phase password recovery:
///   1. Enter email → a 6-digit reset code is sent (logged + returned in debug).
///   2. Enter the code + a new password → the account is updated and the user
///      lands signed in (the router redirect handles navigation).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

enum _Phase { requestEmail, enterCode }

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailKey = GlobalKey<FormState>();
  final _resetKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _codeFocus = FocusNode();

  _Phase _phase = _Phase.requestEmail;
  bool _busy = false;
  bool _obscure = true;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendIn = 45;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendIn == 0) {
        t.cancel();
      } else {
        setState(() => _resendIn--);
      }
    });
  }

  Future<void> _sendCode() async {
    if (!_emailKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final devCode =
          await ref.read(authProvider.notifier).forgotPassword(_email.text.trim());
      setState(() => _phase = _Phase.enterCode);
      _startResendTimer();
      if (devCode != null) {
        _code.text = devCode; // Debug convenience — prefill the code.
        _snack('Reset code sent. Dev code: $devCode', type: SnackType.info);
      } else {
        _snack('Reset code sent — check your email.',
            type: SnackType.success);
      }
    } on AppException catch (e) {
      _snack(e.message, type: SnackType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetKey.currentState!.validate()) return;
    if (_code.text.length != 6) {
      _snack('Enter the 6-digit code.', type: SnackType.error);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final ok = await ref.read(authProvider.notifier).resetPassword(
          email: _email.text.trim(),
          code: _code.text.trim(),
          password: _password.text,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _snack('Password updated. Welcome back!', type: SnackType.success);
      // Router redirect carries the now-authenticated user to /home.
    } else {
      _snack(ref.read(authProvider).error ?? 'Could not reset password.',
          type: SnackType.error);
    }
  }

  void _snack(String message, {required SnackType type}) {
    if (!mounted) return;
    AppSnack.show(context, message, type: type);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: GlowBackground(
        glowAlignment: const Alignment(0.5, -1.1),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.x6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Spacing.x2),
                Row(
                  children: [
                    _circleBack(),
                    const SizedBox(width: Spacing.x4),
                    const DrivlyWordmark(size: 22),
                  ],
                ),
                const SizedBox(height: Spacing.x8),
                Text(
                  _phase == _Phase.requestEmail
                      ? 'Forgot\npassword?'
                      : 'Check your\ninbox.',
                  style: BrandText.display(size: 44, height: 1.05),
                ),
                const SizedBox(height: Spacing.x3),
                Text(
                  _phase == _Phase.requestEmail
                      ? "Enter your email and we'll send you a code to reset it."
                      : 'Enter the 6-digit code we sent to ${_email.text.trim()} '
                          'and choose a new password.',
                  style: textTheme.bodyLarge
                      ?.copyWith(color: BrandColors.mutedFg),
                ),
                const SizedBox(height: Spacing.x8),
                if (_phase == _Phase.requestEmail)
                  _emailForm(textTheme)
                else
                  _resetForm(textTheme),
                const SizedBox(height: Spacing.x6),
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text.rich(
                      TextSpan(
                        text: 'Remembered it?  ',
                        style: textTheme.bodyMedium
                            ?.copyWith(color: BrandColors.mutedFg),
                        children: [
                          TextSpan(
                            text: 'Sign in',
                            style: textTheme.bodyMedium?.copyWith(
                              color: BrandColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.x4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailForm(TextTheme textTheme) {
    return Form(
      key: _emailKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: Validators.email,
            onFieldSubmitted: (_) => _sendCode(),
            decoration: const InputDecoration(
              hintText: 'sarah@drivly.io',
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: Spacing.x6),
          _PrimaryCta(
            label: 'Send reset code',
            busy: _busy,
            onPressed: _sendCode,
          ),
        ],
      ),
    );
  }

  Widget _resetForm(TextTheme textTheme) {
    return Form(
      key: _resetKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CodeBoxes(
            controller: _code,
            focusNode: _codeFocus,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: Spacing.x4),
          Center(
            child: _resendIn > 0
                ? Text(
                    'Resend in 0:${_resendIn.toString().padLeft(2, '0')}',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: BrandColors.mutedFg),
                  )
                : GestureDetector(
                    onTap: _busy ? null : _sendCode,
                    child: Text(
                      'Resend code',
                      style: textTheme.bodyMedium?.copyWith(
                        color: BrandColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: Spacing.x6),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.newPassword],
            validator: Validators.password,
            onFieldSubmitted: (_) => _resetPassword(),
            decoration: InputDecoration(
              hintText: 'New password',
              labelText: 'New password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: Spacing.x6),
          _PrimaryCta(
            label: 'Reset password',
            busy: _busy,
            onPressed: _resetPassword,
          ),
        ],
      ),
    );
  }

  Widget _circleBack() {
    return InkWell(
      onTap: () {
        if (_phase == _Phase.enterCode) {
          setState(() => _phase = _Phase.requestEmail);
        } else {
          context.canPop() ? context.pop() : context.go('/login');
        }
      },
      customBorder: const CircleBorder(),
      child: Container(
        width: Sizes.avatar,
        height: Sizes.avatar,
        decoration: BoxDecoration(
          color: BrandColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: BrandColors.border),
        ),
        child: const Icon(Icons.chevron_left,
            color: BrandColors.foreground, size: Sizes.iconLg),
      ),
    );
  }
}

/// Six-cell code input — mirrors the OTP screen styling for visual consistency.
class _CodeBoxes extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;

  const _CodeBoxes({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final digits = controller.text;
    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              final filled = i < digits.length;
              final active = i == digits.length && i < 6;
              return Container(
                width: 48,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BrandColors.surface2,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(
                    color: active ? BrandColors.primary : BrandColors.border,
                    width: active ? 1.6 : 1.0,
                  ),
                  boxShadow: active ? BrandShadows.glow : null,
                ),
                child: Text(
                  filled ? digits[i] : '',
                  style: BrandText.mono(size: 22),
                ),
              );
            }),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                maxLength: 6,
                showCursor: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: ''),
                onChanged: (_) => onChanged(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary CTA with the brand lime glow halo.
class _PrimaryCta extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onPressed;
  const _PrimaryCta({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.pill),
        boxShadow: BrandShadows.glow,
      ),
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: BrandColors.primaryFg,
                ),
              )
            : Text(label),
      ),
    );
  }
}
