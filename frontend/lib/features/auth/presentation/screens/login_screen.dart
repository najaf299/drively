import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/loading_button.dart';
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
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.x5),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back',
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: Spacing.x2),
                const Text('Sign in to continue your journey.',
                    style: TextStyle(color: BrandColors.mutedFg)),
                const SizedBox(height: Spacing.x8),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                  decoration: const InputDecoration(
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
                LoadingButton(
                  label: 'Sign In',
                  loading: auth.isBusy,
                  onPressed: _submit,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SocialButton(icon: Icons.g_mobiledata, onTap: _google),
                    const SizedBox(width: Spacing.x4),
                    _SocialButton(icon: Icons.apple, onTap: _apple),
                  ],
                ),
                const SizedBox(height: Spacing.x8),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/register'),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SocialButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        width: 64,
        height: 56,
        decoration: BoxDecoration(
          color: BrandColors.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: BrandColors.border),
        ),
        child: Icon(icon, size: 30, color: BrandColors.foreground),
      ),
    );
  }
}
