import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/status_badge.dart';

/// Saved cards are managed by Stripe at checkout time; this build does not
/// persist cards locally. The screen presents the configured methods.
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  void _soon(BuildContext context) =>
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cards are added securely at checkout.')),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x6),
          children: [
            Row(
              children: [
                _BackButton(),
                const SizedBox(width: Spacing.x4),
                Text('Payment methods',
                    style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
            const SizedBox(height: Spacing.x6),
            const _DefaultCard(),
            const SizedBox(height: Spacing.x6),
            Text('Other methods',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: BrandColors.mutedFg)),
            const SizedBox(height: Spacing.x3),
            _MethodRow(
              stripe: BrandColors.warning,
              icon: Icons.credit_card,
              title: 'Mastercard',
              subtitle: '•••• 1245',
              onTap: () => _soon(context),
            ),
            const SizedBox(height: Spacing.x3),
            _MethodRow(
              stripe: BrandColors.foreground,
              icon: Icons.phone_iphone,
              title: 'Apple Pay',
              subtitle: 'Default device',
              onTap: () => _soon(context),
            ),
            const SizedBox(height: Spacing.x3),
            _MethodRow(
              stripe: BrandColors.success,
              icon: Icons.account_balance,
              title: 'Bank transfer',
              subtitle: 'ACH · 2–3 days',
              onTap: () => _soon(context),
            ),
            const SizedBox(height: Spacing.x6),
            _AddMethodButton(onTap: () => _soon(context)),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.surface,
      shape: const CircleBorder(side: BorderSide(color: BrandColors.border)),
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back, color: BrandColors.foreground, size: 20),
        ),
      ),
    );
  }
}

class _DefaultCard extends StatelessWidget {
  const _DefaultCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.x5),
      decoration: BoxDecoration(
        gradient: BrandGradients.accent,
        borderRadius: BorderRadius.circular(Radii.xxl),
        boxShadow: BrandShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('VISA · DEFAULT',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: BrandColors.foreground,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      )),
              const Spacer(),
              const StatusBadge('DEFAULT', tone: BadgeTone.neutral),
            ],
          ),
          const SizedBox(height: Spacing.x6),
          Text(
            '••••  4829',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: BrandColors.foreground,
                  letterSpacing: 3,
                ),
          ),
          const SizedBox(height: Spacing.x5),
          const Row(
            children: [
              _CardField(label: 'EXP', value: '08/27'),
              SizedBox(width: Spacing.x8),
              _CardField(label: 'CVV', value: '•••'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  final String label;
  final String value;
  const _CardField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: BrandColors.foreground.withValues(alpha: 0.7),
                  letterSpacing: 1,
                )),
        const SizedBox(height: 2),
        Text(value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: BrandColors.foreground,
                )),
      ],
    );
  }
}

class _MethodRow extends StatelessWidget {
  final Color stripe;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MethodRow({
    required this.stripe,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.surface,
      borderRadius: BorderRadius.circular(Radii.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.xl),
        child: Container(
          padding: const EdgeInsets.all(Spacing.x3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.xl),
            border: Border.all(color: BrandColors.border),
          ),
          child: Row(
            children: [
              _CardThumb(stripe: stripe, icon: icon),
              const SizedBox(width: Spacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: BrandColors.mutedFg),
            ],
          ),
        ),
      ),
    );
  }
}

/// A ~56x40 card thumbnail with a brand-colour stripe along the bottom.
class _CardThumb extends StatelessWidget {
  final Color stripe;
  final IconData icon;
  const _CardThumb({required this.stripe, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 40,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: BrandColors.surface2,
        borderRadius: BorderRadius.circular(Radii.xs),
        border: Border.all(color: BrandColors.border),
      ),
      child: Stack(
        children: [
          Center(child: Icon(icon, color: stripe, size: 20)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(height: 6, color: stripe),
          ),
        ],
      ),
    );
  }
}

class _AddMethodButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddMethodButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.xl),
      child: const DottedBorderBox(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Spacing.x4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: BrandColors.primary, size: 20),
              SizedBox(width: Spacing.x2),
              Text('Add new method',
                  style: TextStyle(
                      color: BrandColors.primary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A rounded box with a dashed border (used for the "add method" affordance).
class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(),
      child: child,
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BrandColors.borderStrong
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const radius = Radii.xl;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dashWidth = 6.0;
    const dashGap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
