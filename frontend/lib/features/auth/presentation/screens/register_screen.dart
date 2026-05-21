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
    final textTheme = Theme.of(context).textTheme;
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
                // Title — displayMedium (no hardcoded fontSize/weight).
                Text(
                  'Create\nyour account',
                  style: textTheme.displayMedium?.copyWith(height: 1.1),
                ),
                const SizedBox(height: Spacing.x6),
                // Role toggle — surface2 pill track, selected = primary/primaryFg.
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
                // 4-bar strength meter.
                _StrengthMeter(strength: _strength),
                const SizedBox(height: Spacing.x4),
                // Terms checkbox.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: Sizes.icon,
                      width: Sizes.icon,
                      child: Checkbox(
                        value: _agreed,
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                      ),
                    ),
                    const SizedBox(width: Spacing.x3),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text.rich(
                          TextSpan(
                            text: 'I agree to the ',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: BrandColors.mutedFg),
                            children: const [
                              TextSpan(
                                text: 'Terms',
                                style: TextStyle(
                                  color: BrandColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' & '),
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
                // Primary CTA with glow — radius Radii.pill (spec §shared rules).
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
                        : const Text('Create account'),
                  ),
                ),
                const SizedBox(height: Spacing.x4),
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text.rich(
                      TextSpan(
                        text: 'Have an account?  ',
                        style: textTheme.bodyMedium
                            ?.copyWith(color: BrandColors.mutedFg),
                        children: const [
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

// ---------------------------------------------------------------------------
// Role toggle — surface2 pill track, selected segment = primary/primaryFg.
// ---------------------------------------------------------------------------

class _RoleToggle extends StatelessWidget {
  final String role;
  final ValueChanged<String> onChanged;
  const _RoleToggle({required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BrandColors.surface2,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        children: [
          _segment(context, 'I want to rent', 'customer'),
          _segment(context, 'I want to host', 'host'),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, String label, String value) {
    final selected = role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: Spacing.x3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? BrandColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? BrandColors.primaryFg : BrandColors.mutedFg,
                ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Strength meter — 4-bar style (spec §7.4).
// ---------------------------------------------------------------------------

class _StrengthMeter extends StatelessWidget {
  final int strength; // 0..4
  const _StrengthMeter({required this.strength});

  @override
  Widget build(BuildContext context) {
    final Color barColor;
    final String label;

    if (strength <= 1) {
      barColor = BrandColors.destructive;
      label = 'Weak';
    } else if (strength == 2) {
      barColor = BrandColors.warning;
      label = 'Medium';
    } else {
      barColor = BrandColors.success;
      label = 'Strong';
    }

    return Row(
      children: [
        // Four individual bars.
        Expanded(
          child: Row(
            children: List.generate(4, (i) {
              final filled = i < strength;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? Spacing.x1 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 6,
                    decoration: BoxDecoration(
                      color: filled ? barColor : BrandColors.surface2,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: Spacing.x3),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: barColor),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step header — shared across multi-step sign-up flow.
// ---------------------------------------------------------------------------

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
