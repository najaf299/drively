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
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
              ),
              const SizedBox(height: Spacing.x2),
              Text(
                _phone.text.isEmpty
                    ? 'We\'ll text you a 6-digit verification code.'
                    : 'We sent a 6-digit code to ${_phone.text}',
                style: const TextStyle(color: BrandColors.mutedFg, fontSize: 15),
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
                // Six digit circles backed by a single hidden field so the
                // existing verify logic is unchanged.
                _OtpCircles(
                  controller: _code,
                  focusNode: _codeFocus,
                  onCompleted: _verify,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: Spacing.x6),
                Center(
                  child: _resendIn > 0
                      ? Text(
                          'Didn\'t receive code? Resend in '
                          '0:${_resendIn.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: BrandColors.mutedFg),
                        )
                      : Text.rich(
                          TextSpan(
                            text: 'Didn\'t receive code?  ',
                            style:
                                const TextStyle(color: BrandColors.mutedFg),
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: GestureDetector(
                                  onTap: _send,
                                  child: const Text(
                                    'Resend',
                                    style: TextStyle(
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
                  child: const Text(
                    'Use email instead',
                    style: TextStyle(
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

/// A row of six circular digit slots backed by a single hidden [TextField].
class _OtpCircles extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;
  final VoidCallback onCompleted;

  const _OtpCircles({
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
              final active = i == digits.length;
              return Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: filled ? BrandColors.primary : BrandColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active
                        ? BrandColors.primary
                        : filled
                            ? BrandColors.primary
                            : BrandColors.border,
                    width: active ? 2 : 1,
                  ),
                ),
                child: Text(
                  filled ? digits[i] : '',
                  style: const TextStyle(
                    color: BrandColors.primaryFg,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
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

/// Full-width lime pill button with an inline busy spinner.
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
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
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

/// Circular chevron back button followed by a step-progress label.
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: BrandColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: BrandColors.border),
            ),
            child: const Icon(Icons.chevron_left,
                color: BrandColors.foreground, size: 26),
          ),
        ),
        const SizedBox(width: Spacing.x4),
        Text(
          label,
          style: const TextStyle(
            color: BrandColors.mutedFg,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
