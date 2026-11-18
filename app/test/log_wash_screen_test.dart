import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strandwise/features/calendar/log_wash_screen.dart';
import 'package:strandwise/models/hair_profile.dart';
import 'package:strandwise/models/wash_log.dart';
import 'package:strandwise/theme/app_theme.dart';

void main() {
  testWidgets('requires feel before/after and saves feel and styling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    WashLog? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => saved = await Navigator.push<WashLog>(
              context,
              MaterialPageRoute(builder: (_) => const LogWashScreen()),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    FilledButton button(String label) =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));
    Future<void> next() async {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Step 1 of 7'), findsOneWidget);
    expect(
      find.text('How did your hair feel before this wash day?'),
      findsOneWidget,
    );
    expect(button('Continue').onPressed, isNull);
    await tester.tap(find.text('Oily'));
    await tester.pumpAndSettle();
    await next();

    await next(); // pre-poo: No
    await tester.enterText(find.byType(TextField), 'Shampoo');
    await tester.pumpAndSettle();
    await next();
    await tester.tap(find.text('Rinse-out'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Conditioner');
    await tester.pumpAndSettle();
    await next();

    // Style: styling is optional and multi-select.
    expect(button('Continue').onPressed, isNotNull);
    await tester.tap(find.text('Wear it out'));
    await tester.tap(find.text('Heat styled'));
    await tester.pumpAndSettle();
    await next();

    expect(
      find.text('How does your hair feel after this wash day?'),
      findsOneWidget,
    );
    expect(button('Continue').onPressed, isNull);
    await tester.tap(find.text('Dry'));
    await tester.pumpAndSettle();

    // Back keeps the styling selection.
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Wear it out'))
          .selected,
      isTrue,
    );
    await next();
    await next();
    await tester.tap(find.text('Save wash day'));
    await tester.pumpAndSettle();

    expect(saved?.feelBefore, HairFeel.oily);
    expect(saved?.feelAfter, HairFeel.dry);
    expect(saved?.styling, {HairStyling.out, HairStyling.heatStyled});
  });
}
