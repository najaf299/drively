import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivly/app/theme.dart';
import 'package:drivly/shared/widgets/app_dialog.dart';

void main() {
  group('DialogActions', () {
    testWidgets('always renders a Cancel button plus the confirm label',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: DrivlyTheme.dark,
        home: Scaffold(
          body: DialogActions(
            confirmLabel: 'Decline',
            onCancel: () {},
            onConfirm: () {},
          ),
        ),
      ));

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      // Cancel is the tonal OutlinedButton; confirm is the FilledButton.
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('invokes the right callbacks', (tester) async {
      var cancelled = false;
      var confirmed = false;
      await tester.pumpWidget(MaterialApp(
        theme: DrivlyTheme.dark,
        home: Scaffold(
          body: DialogActions(
            confirmLabel: 'OK',
            onCancel: () => cancelled = true,
            onConfirm: () => confirmed = true,
          ),
        ),
      ));

      await tester.tap(find.text('Cancel'));
      await tester.tap(find.text('OK'));
      expect(cancelled, isTrue);
      expect(confirmed, isTrue);
    });
  });

  group('showConfirmDialog', () {
    testWidgets('returns true on confirm and false on cancel', (tester) async {
      late bool result;
      await tester.pumpWidget(MaterialApp(
        theme: DrivlyTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showConfirmDialog(
                  context,
                  title: 'Sign out',
                  message: 'Are you sure?',
                  confirmLabel: 'Sign out',
                  destructive: true,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out'), findsWidgets);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });
}
