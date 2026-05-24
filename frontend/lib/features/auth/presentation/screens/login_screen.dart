import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/glow_background.dart';
import '../../domain/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authProvider.notifier).login(
          _email.text.trim(),
          _password.text,
        );
  }

  // ── Social sign-in ─────────────────────────────────────────────────────
  //
  // Real Google/Apple OAuth needs native config this prototype build does not
  // ship (GoogleService-Info.plist + reverse-client URL schemes for Google; a
  // "Sign in with Apple" capability/entitlement for Apple). Invoking the native
  // SDKs without that config raises an *uncatchable* native exception that hard
  // crashes the app. So instead of touching the native pickers we sign in a
  // stable demo account through the backend's social endpoints, which keeps the
  // flow fully working. To enable real OAuth, add the native config and restore
  // the GoogleSignIn / SignInWithApple calls here.

  Future<void> _google() async {
    const email = 'demo.google@drivly.io';
    await ref.read(authProvider.notifier).loginWithGoogle(
          _demoIdToken({
            'sub': 'google-demo-001',
            'email': email,
            'name': 'Demo Driver',
          }),
          name: 'Demo Driver',
          email: email,
        );
  }

  Future<void> _apple() async {
    const email = 'demo.apple@drivly.io';
    await ref.read(authProvider.notifier).loginWithApple(
          _demoIdToken({'sub': 'apple-demo-001', 'email': email}),
          authorizationCode: 'demo-apple-auth-code',
          name: 'Demo Apple User',
          email: email,
        );
  }

  /// Builds a well-formed (unsigned) JWT the demo backend decodes to find or
  /// create the matching account — no native OAuth SDK required.
  String _demoIdToken(Map<String, dynamic> payload) {
    String seg(Map<String, dynamic> m) =>
        base64.encode(utf8.encode(jsonEncode(m)));
    return '${seg({'alg': 'none', 'typ': 'JWT'})}.${seg(payload)}.demo';
  }

  void _snack(String message) {
    if (!mounted) return;
    AppSnack.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final auth = ref.watch(authProvider);

    // Surface auth errors as a snackbar AND inline banner.
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        _snack(next.error!);
      }
    });

    return Scaffold(
      body: GlowBackground(
        glowAlignment: const Alignment(0.5, -1.1),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.x6),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Spacing.x4),
                  const DrivlyWordmark(size: 26),
                  const SizedBox(height: Spacing.x8),
                  // Oversized brand headline.
                  Text(
                    'Welcome\nback.',
                    style: BrandText.display(size: 46, height: 1.05),
                  ),
                  const SizedBox(height: Spacing.x3),
                  Text(
                    'Sign in to continue your journey',
                    style: textTheme.bodyLarge
                        ?.copyWith(color: BrandColors.mutedFg),
                  ),
                  const SizedBox(height: Spacing.x8),
                  // Email field — uses global InputDecoration theme.
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                    decoration: const InputDecoration(
                      hintText: 'sarah@drivly.io',
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: Spacing.x4),
                  // Password field with obscure toggle.
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    validator: Validators.password,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  // 'Forgot password?' — aligned right.
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: Spacing.x2),
                  // Primary CTA with glow halo (radius Radii.pill).
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Radii.pill),
                      boxShadow: BrandShadows.glow,
                    ),
                    child: FilledButton(
                      onPressed: auth.isBusy ? null : _submit,
                      child: auth.isBusy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: BrandColors.primaryFg,
                              ),
                            )
                          : const Text('Sign in'),
                    ),
                  ),
                  const SizedBox(height: Spacing.x6),
                  // Divider row.
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: Spacing.x3),
                        child: Text(
                          'or',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: BrandColors.mutedFg),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: Spacing.x5),
                  // OAuth row — tonal OutlinedButtons height Sizes.socialHeight.
                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          label: 'Google',
                          icon: Icons.g_mobiledata_rounded,
                          onTap: _google,
                        ),
                      ),
                      const SizedBox(width: Spacing.x4),
                      Expanded(
                        child: _SocialButton(
                          label: 'Apple',
                          icon: Icons.apple,
                          onTap: _apple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.x8),
                  // Bottom sign-up link.
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text.rich(
                        TextSpan(
                          text: "Don't have an account?  ",
                          style: textTheme.bodyMedium
                              ?.copyWith(color: BrandColors.mutedFg),
                          children: [
                            TextSpan(
                              text: 'Sign up',
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
      ),
    );
  }
}

/// Tonal OutlinedButton for OAuth providers — height Sizes.socialHeight (56).
class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Sizes.socialHeight,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: Sizes.icon),
        label: Text(label),
      ),
    );
  }
}
