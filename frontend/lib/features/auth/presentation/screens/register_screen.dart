import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  String _role = 'customer';
  bool _obscure = true;
  bool _agreed = false;
  int _strength = 0;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms to continue.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    await ref.read(authProvider.notifier).register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          role: _role,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error!)));
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
                const _StepHeader(label: 'Step 1 of 3'),
                const SizedBox(height: Spacing.x6),
                Text(
                  'Create\nyour account',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.8,
                      ),
                ),
                const SizedBox(height: Spacing.x6),
                _RoleToggle(
                  role: _role,
                  onChanged: (r) => setState(() => _role = r),
                ),
                const SizedBox(height: Spacing.x5),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.name,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: Spacing.x4),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: Spacing.x4),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    hintText: '+15551234567',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: Spacing.x4),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  validator: Validators.password,
                  onChanged: (v) => setState(
                      () => _strength = Validators.passwordStrength(v)),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.x3),
                _StrengthMeter(strength: _strength),
                const SizedBox(height: Spacing.x4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _agreed,
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.sm),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.x3),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text.rich(
                          TextSpan(
                            text: 'I agree to the ',
                            style: TextStyle(color: BrandColors.mutedFg),
                            children: [
                              TextSpan(
                                text: 'Terms',
                                style: TextStyle(
                                  color: BrandColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
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
                const SizedBox(height: Spacing.x5),
                // Primary CTA wired to the existing register flow with busy state.
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
                        : const Text('Create account'),
                  ),
                ),
                const SizedBox(height: Spacing.x4),
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Have an account?  ',
                        style: TextStyle(color: BrandColors.mutedFg),
                        children: [
                          TextSpan(
                            text: 'Sign in',
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

class _RoleToggle extends StatelessWidget {
  final String role;
  final ValueChanged<String> onChanged;
  const _RoleToggle({required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        children: [
          _segment('I want to rent', 'customer'),
          _segment('I want to host', 'host'),
        ],
      ),
    );
  }

  Widget _segment(String label, String value) {
    final selected = role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? BrandColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? BrandColors.primaryFg : BrandColors.mutedFg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  final int strength; // 0..4
  const _StrengthMeter({required this.strength});

  @override
  Widget build(BuildContext context) {
    final color = strength <= 1
        ? BrandColors.destructive
        : strength == 2
            ? BrandColors.warning
            : BrandColors.success;
    final label = strength <= 1
        ? 'Weak'
        : strength == 2
            ? 'Medium'
            : 'Strong';
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Radii.pill),
            child: LinearProgressIndicator(
              value: strength / 4,
              minHeight: 6,
              backgroundColor: BrandColors.surface2,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: Spacing.x3),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}

/// Circular chevron back button followed by a step-progress label, shared
/// across the multi-step sign-up flow (sign up, OTP, KYC).
class _StepHeader extends StatelessWidget {
  final String label;
  const _StepHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () =>
              context.canPop() ? context.pop() : context.go('/onboarding'),
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
