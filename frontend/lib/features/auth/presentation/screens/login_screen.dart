import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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

  Future<void> _google() async {
    try {
      final account = await GoogleSignIn(scopes: const ['email']).signIn();
      final idToken = (await account?.authentication)?.idToken;
      if (idToken == null) return;
      await ref.read(authProvider.notifier).loginWithGoogle(idToken);
    } catch (_) {
      _snack('Google sign-in is not configured for this build.');
    }
  }

  Future<void> _apple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      _snack('Apple sign-in is only available on Apple devices.');
      return;
    }
    try {
      final cred = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final token = cred.identityToken;
      if (token == null) return;
      await ref.read(authProvider.notifier).loginWithApple(token);
    } catch (_) {
      _snack('Apple sign-in is not configured for this build.');
    }
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
                  // Inline error banner when auth.error != null.
                  if (auth.error != null) ...[
                    _ErrorBanner(message: auth.error!),
                    const SizedBox(height: Spacing.x5),
                  ],
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
                        icon: Icon(_obscure
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  // 'Forgot password?' — aligned right.
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _snack(
                          'Password reset is coming soon. Contact support.'),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.x3),
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

/// Inline error banner shown when `auth.error != null` (spec §7.3).
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.x4, vertical: Spacing.x3),
      decoration: BoxDecoration(
        color: BrandColors.destructiveBg,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
            color: BrandColors.destructive.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline,
              color: BrandColors.destructive, size: Sizes.icon),
          const SizedBox(width: Spacing.x3),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: BrandColors.destructive),
            ),
          ),
        ],
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
