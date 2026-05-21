import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/status_badge.dart';

/// Saved cards — §4.3 / §7.22.
/// Each saved card is a MiniCard ~96h using BrandGradients.surfaceCard bg.
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
            // Header row with back button
            Row(
              children: [
                _BackButton(),
                const SizedBox(width: Spacing.x4),
                Text('Payment methods',
                    style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
            const SizedBox(height: Spacing.x6),
            // Default card — MiniCard with surfaceCard gradient
            _MiniCard(
              brand: 'Visa',
              lastFour: '4829',
              expiry: '08/27',
              isDefault: true,
              onTap: () => _soon(context),
            ),
            const SizedBox(height: Spacing.x3),
            _MiniCard(
              brand: 'Mastercard',
              lastFour: '1245',
              expiry: '09/27',
              isDefault: false,
              onTap: () => _soon(context),
            ),
            const SizedBox(height: Spacing.x6),
            // Add payment method — dashed-border tile
            _AddMethodButton(onTap: () => _soon(context)),
          ],
        ),
      ),
    );
  }
}

// ─── Mini card (~96h, surfaceCard gradient) ────────────────────────────────────

class _MiniCard extends StatelessWidget {
  final String brand;
  final String lastFour;
  final String expiry;
  final bool isDefault;
  final VoidCallback onTap;

  const _MiniCard({
    required this.brand,
    required this.lastFour,
    required this.expiry,
    required this.isDefault,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.x5, vertical: Spacing.x3),
        decoration: BoxDecoration(
          gradient: BrandGradients.surfaceCard,
          borderRadius: BorderRadius.circular(Radii.xl),
          border: Border.all(color: BrandColors.border),
          boxShadow: BrandShadows.card,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Brand mark top-left (within the row, leading)
            _BrandMark(brand: brand),
            const SizedBox(width: Spacing.x4),
            // Card number mono center
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•••• $lastFour',
                    style: BrandText.mono(
                      size: 17,
                      weight: FontWeight.w600,
                      color: BrandColors.foreground,
                      spacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Exp $expiry',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: BrandColors.mutedFg),
                  ),
                ],
              ),
            ),
            // Default badge
            if (isDefault)
              const StatusBadge('Default', tone: BadgeTone.success)
            else
              const Icon(Icons.chevron_right, color: BrandColors.mutedFg),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final String brand;
  const _BrandMark({required this.brand});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (brand.toLowerCase()) {
      'visa' => (Icons.credit_card, BrandColors.info),
      'mastercard' => (Icons.credit_card, BrandColors.warning),
      'amex' => (Icons.credit_card, BrandColors.success),
      _ => (Icons.credit_card, BrandColors.mutedFg),
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, color: color, size: Sizes.icon),
    );
  }
}

// ─── Add method dashed tile ───────────────────────────────────────────────────

class _AddMethodButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddMethodButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.xl),
      child: DottedBorderBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.x4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: BrandColors.primary, size: 20),
              const SizedBox(width: Spacing.x2),
              Text(
                'Add payment method',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: BrandColors.primary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Back button ──────────────────────────────────────────────────────────────

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
          child:
              Icon(Icons.arrow_back, color: BrandColors.foreground, size: 20),
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
