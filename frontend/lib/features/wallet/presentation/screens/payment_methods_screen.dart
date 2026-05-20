import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Saved cards are managed by Stripe at checkout time; this build does not
/// persist cards locally. The screen documents that flow.
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment methods')),
      body: const Padding(
        padding: EdgeInsets.all(Spacing.x6),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.credit_card_outlined,
                  size: 56, color: BrandColors.mutedFg),
              SizedBox(height: Spacing.x4),
              Text('Cards are added at checkout',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: Spacing.x2),
              Text(
                'Drivly uses Stripe to process card payments securely during '
                'booking. Your wallet balance is available now.',
                textAlign: TextAlign.center,
                style: TextStyle(color: BrandColors.mutedFg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
