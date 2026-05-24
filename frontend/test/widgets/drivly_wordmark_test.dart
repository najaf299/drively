import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivly/app/theme.dart';
import 'package:drivly/shared/widgets/glow_background.dart';

void main() {
  group('DrivlyWordmark', () {
    testWidgets('renders the wordmark text', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Center(child: DrivlyWordmark(size: 40))),
      ));
      expect(find.text('drivly'), findsOneWidget);
    });

    testWidgets('shows a lime accent dot by default', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Center(child: DrivlyWordmark(size: 60))),
      ));

      // The green dot is a real circular Container (not a text period), tinted
      // with the lime brand primary.
      final dot =
          tester.widgetList<Container>(find.byType(Container)).where((c) {
        final d = c.decoration;
        return d is BoxDecoration &&
            d.shape == BoxShape.circle &&
            d.color == BrandColors.primary;
      });
      expect(dot, isNotEmpty);
    });

    testWidgets('hides the dot when showDot is false', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(child: DrivlyWordmark(size: 40, showDot: false)),
        ),
      ));

      final dot =
          tester.widgetList<Container>(find.byType(Container)).where((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.shape == BoxShape.circle;
      });
      expect(dot, isEmpty);
    });
  });
}
