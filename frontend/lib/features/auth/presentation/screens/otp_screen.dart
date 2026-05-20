import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../../domain/providers/auth_provider.dart';

/// Phone OTP flow: enter number → receive code → verify. Existing accounts are
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
  bool _codeSent = false;
  bool _busy = false;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null) _phone.text = widget.initialPhone!;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _code.dispose();
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
      appBar: AppBar(title: const Text('Verify your number')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.x5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _codeSent ? 'Enter the 6-digit code' : 'What\'s your number?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: Spacing.x2),
              Text(
                _codeSent
                    ? 'We sent a code to ${_phone.text}'
                    : 'We\'ll text you a verification code.',
                style: const TextStyle(color: BrandColors.mutedFg),
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
                const SizedBox(height: Spacing.x5),
                LoadingButton(
                  label: 'Send code',
                  loading: _busy,
                  onPressed: _send,
                ),
              ] else ...[
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(counterText: ''),
                  onChanged: (v) {
                    if (v.length == 6) _verify();
                  },
                ),
                const SizedBox(height: Spacing.x4),
                LoadingButton(
                  label: 'Verify',
                  loading: _busy,
                  onPressed: _verify,
                ),
                const SizedBox(height: Spacing.x3),
                Center(
                  child: _resendIn > 0
                      ? Text(
                          'Resend in 0:${_resendIn.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: BrandColors.mutedFg))
                      : TextButton(
                          onPressed: _send, child: const Text('Resend code')),
                ),
              ],
              const SizedBox(height: Spacing.x4),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Use email instead'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
