import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/providers/auth_provider.dart';

/// Phone OTP flow: enter number -> receive code -> verify. Existing accounts are
/// signed in; unknown numbers are directed to registration.
class OtpScreen extends ConsumerStatefulWidget {
  final String? initialPhone;
  const OtpScreen({super.key, this.initialPhone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  bool _codeSent = false;
  bool _busy = false;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      _phone.text = widget.initialPhone!;
      // A phone was supplied by the router; send the code straight away.
      WidgetsBinding.instance.addPostFrameCallback((_) => _send());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _code.dispose();
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

  Future<void> _send() async {
    if (_phone.text.trim().isEmpty) {
      _snack('Enter your phone number first.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authProvider.notifier).sendOtp(_phone.text.trim());
      setState(() => _codeSent = true);
      _startResendTimer();
      _snack('Verification code sent.');
    } on AppException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_code.text.length != 6) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final ok = await ref
          .read(authProvider.notifier)
          .verifyOtp(_phone.text.trim(), _code.text.trim());
      if (!ok && mounted) {
        _snack('No account found for this number. Please register.');
      }
      // On success the router redirect navigates away automatically.
    } on AppException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.x6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _StepHeader(label: 'Step 2 of 3'),
              const SizedBox(height: Spacing.x6),
              Text(
                'Verify your phone',
                style: textTheme.displaySmall,
              ),
              const SizedBox(height: Spacing.x2),
              Text(
                _phone.text.isEmpty
                    ? "We'll text you a 6-digit verification code."
                    : 'We sent a 6-digit code to ${_phone.text}',
                style: textTheme.bodyLarge
                    ?.copyWith(color: BrandColors.mutedFg),
              ),
              const SizedBox(height: Spacing.x8),
              if (!_codeSent) ...[
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: '+15551234567',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: Spacing.x6),
                _PrimaryButton(
                  label: 'Send code',
                  busy: _busy,
                  onPressed: _send,
                ),
              ] else ...[
                // Six digit boxes backed by a single hidden field.
                _OtpBoxes(
                  controller: _code,
                  focusNode: _codeFocus,
                  onCompleted: _verify,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: Spacing.x6),
                // Resend row: countdown or active link.
                Center(
                  child: _resendIn > 0
                      ? Text(
                          'Resend in '
                          '0:${_resendIn.toString().padLeft(2, '0')}',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: BrandColors.mutedFg),
                        )
                      : GestureDetector(
                          onTap: _send,
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
                _PrimaryButton(
                  label: 'Verify',
                  busy: _busy,
                  onPressed: _verify,
                ),
              ],
              const SizedBox(height: Spacing.x4),
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text(
                    'Use email instead',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: BrandColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// OTP boxes — 6 cells 48×56, surface2 fill, radius Radii.md.
// Active/focused: border 1.6 primary + BrandShadows.glow.
// Digits rendered with BrandText.mono(size: 22).
// ---------------------------------------------------------------------------

class _OtpBoxes extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;
  final VoidCallback onCompleted;

  const _OtpBoxes({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onCompleted,
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
              // Active = the next empty slot (cursor position).
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
          // Invisible field that actually captures input.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                showCursor: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: ''),
                onChanged: (v) {
                  onChanged();
                  if (v.length == 6) onCompleted();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Primary CTA with glow — full pill (theme-driven), spec §shared rules.
// ---------------------------------------------------------------------------

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onPressed;
  const _PrimaryButton({
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
            ? SizedBox(
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

// ---------------------------------------------------------------------------
// Step header — circular chevron back + step label.
// ---------------------------------------------------------------------------

class _StepHeader extends StatelessWidget {
  final String label;
  const _StepHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.canPop() ? context.pop() : context.go('/login'),
          customBorder: const CircleBorder(),
          child: Container(
            width: Sizes.avatar,
            height: Sizes.avatar,
            decoration: BoxDecoration(
              color: BrandColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: BrandColors.border),
            ),
            child: Icon(Icons.chevron_left,
                color: BrandColors.foreground, size: Sizes.iconLg),
          ),
        ),
        const SizedBox(width: Spacing.x4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: BrandColors.mutedFg),
        ),
      ],
    );
  }
}
