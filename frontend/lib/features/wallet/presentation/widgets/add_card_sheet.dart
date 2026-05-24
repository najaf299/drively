import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../domain/providers/payment_methods_provider.dart';

/// Bottom sheet to add a saved card. Detects the brand from the first digit and
/// only persists the last four (full numbers are never stored client-side).
/// Returns `true` via [Navigator.pop] when a card was added.
class AddCardSheet extends ConsumerStatefulWidget {
  const AddCardSheet({super.key});

  @override
  ConsumerState<AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends ConsumerState<AddCardSheet> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _expiry = TextEditingController();

  @override
  void dispose() {
    _number.dispose();
    _expiry.dispose();
    super.dispose();
  }

  String _brandFor(String number) {
    if (number.startsWith('4')) return 'Visa';
    if (number.startsWith('5')) return 'Mastercard';
    if (number.startsWith('3')) return 'Amex';
    return 'Card';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final digits = _number.text.replaceAll(RegExp(r'\D'), '');
    ref.read(savedCardsProvider.notifier).add(
          brand: _brandFor(digits),
          lastFour: digits.substring(digits.length - 4),
          expiry: _expiry.text.trim(),
        );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: Spacing.x5,
        right: Spacing.x5,
        top: Spacing.x5,
        bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.x5,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add card', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Spacing.x5),
            TextFormField(
              controller: _number,
              keyboardType: TextInputType.number,
              inputFormatters: [_CardNumberInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Card number',
                hintText: '4242 4242 4242 4242',
                prefixIcon: Icon(Icons.credit_card),
              ),
              validator: (v) {
                final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                // Amex is 15 digits; everything else is 16.
                final need = d.startsWith('3') ? 15 : 16;
                if (d.length != need) {
                  return 'Enter all $need digits of your card number';
                }
                return null;
              },
            ),
            const SizedBox(height: Spacing.x4),
            TextFormField(
              controller: _expiry,
              keyboardType: TextInputType.number,
              inputFormatters: [_ExpiryInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Expiry (MM/YY)',
                hintText: '08/27',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              validator: (v) {
                if (!RegExp(r'^(0[1-9]|1[0-2])/\d{2}$')
                    .hasMatch((v ?? '').trim())) {
                  return 'Use MM/YY (e.g. 08/27)';
                }
                return null;
              },
            ),
            const SizedBox(height: Spacing.x6),
            FilledButton(onPressed: _submit, child: const Text('Add card')),
          ],
        ),
      ),
    );
  }
}

/// Strips non-digits, caps at 16, and groups into "#### #### #### ####".
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 16) digits = digits.substring(0, 16);
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Strips non-digits, caps at 4 (MMYY) and auto-inserts the slash → "MM/YY".
class _ExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    // Slash appears once the 3rd digit is typed (avoids a backspace trap).
    final text = digits.length >= 3
        ? '${digits.substring(0, 2)}/${digits.substring(2)}'
        : digits;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
