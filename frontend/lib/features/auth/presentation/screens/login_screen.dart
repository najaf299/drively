import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/validators.dart';
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // Surface auth errors as a snackbar.
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        _snack(next.error!);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.x6),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Spacing.x4),
                // Wordmark with a lime period.
                const Text.rich(
                  TextSpan(
                    text: 'drivly',
                    style: TextStyle(
                      color: BrandColors.foreground,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    children: [
                      TextSpan(
                        text: '.',
                        style: TextStyle(color: BrandColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.x10),
                Text(
                  'Welcome back.',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                ),
                const SizedBox(height: Spacing.x2),
                const Text(
                  'Sign in to continue your journey',
                  style: TextStyle(color: BrandColors.mutedFg, fontSize: 15),
                ),
                const SizedBox(height: Spacing.x8),
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _snack(
                        'Password reset is coming soon. Contact support.'),
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: Spacing.x2),
                // Primary CTA wired to the existing login flow with busy state.
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                const Row(
                  children: [
                    Expanded(child: Divider(color: BrandColors.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: Spacing.x3),
                      child: Text('or continue with',
                          style: TextStyle(color: BrandColors.mutedFg)),
                    ),
                    Expanded(child: Divider(color: BrandColors.border)),
                  ],
                ),
                const SizedBox(height: Spacing.x5),
                Row(
                  children: [
                    Expanded(
                      child: _SocialButton(
                        onTap: _google,
                        child: const Text(
                          'G',
                          style: TextStyle(
                            color: BrandColors.foreground,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.x4),
                    Expanded(
                      child: _SocialButton(
                        onTap: _apple,
                        child: const Icon(Icons.apple,
                            size: 28, color: BrandColors.foreground),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.x8),
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/register'),
                    child: const Text.rich(
                      TextSpan(
                        text: 'New here?  ',
                        style: TextStyle(color: BrandColors.mutedFg),
                        children: [
                          TextSpan(
                            text: 'Sign up',
                            style: TextStyle(
                              color: BrandColors.primary,
                              fontWeight: FontWeight.w600,
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
}

/// A rounded dark square used for the social sign-in providers.
class _SocialButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _SocialButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.card),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: BrandColors.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: BrandColors.border),
        ),
        child: child,
      ),
    );
  }
}
