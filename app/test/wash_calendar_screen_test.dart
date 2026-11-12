import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strandwise/data/wash_history_store.dart';
import 'package:strandwise/features/calendar/wash_calendar_screen.dart';
import 'package:strandwise/models/hair_profile.dart';
import 'package:strandwise/theme/app_theme.dart';

void main() {
  testWidgets('logs a wash through pre-poo, cleanse, condition, style, rating', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const WashCalendarScreen(profile: HairProfile(curlPattern: '3B')),
      ),
    );
    await tester.pumpAndSettle();

    FilledButton continueButton(String label) =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));

    await tester.tap(find.text('Log today’s wash'));
    await tester.pumpAndSettle();

    // Pre-poo: type is required once "Yes" is chosen.
    expect(find.text('What type?'), findsNothing);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(continueButton('Continue').onPressed, isNull);
    await tester.tap(find.text('Oil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Cleanse
    expect(continueButton('Continue').onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'Gentle Shampoo');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Condition: "Both" asks for each conditioner name.
    await tester.tap(find.text('Both'));
    await tester.pumpAndSettle();
    expect(continueButton('Continue').onPressed, isNull);
    await tester.enterText(
      find.widgetWithText(TextField, 'Rinse-out conditioner name'),
      'Slip Conditioner',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Deep conditioner name'),
      'Repair Mask',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Style: add one product with +, leave a second typed for Continue to keep.
    await tester.enterText(find.byType(TextField), 'Gel');
    await tester.tap(find.byTooltip('Add product'));
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Oil');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Rate every product
    for (final name in [
      'Gentle Shampoo',
      'Slip Conditioner',
      'Repair Mask',
      'Gel',
      'Oil',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.byType(Slider), findsNWidgets(5));
    await tester.tap(find.text('Save wash day'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final saved = (await WashHistoryStore.load()).single;
    expect(saved.prePooType?.label, 'Oil');
    expect(saved.shampoo, 'Gentle Shampoo');
    expect(saved.rinseOutConditioner, 'Slip Conditioner');
    expect(saved.deepConditioner, 'Repair Mask');
    expect(saved.styleProducts, ['Gel', 'Oil']);
    expect(saved.ratings.keys, saved.products);
    expect(saved.ratings.values.every((r) => r >= 1 && r <= 10), isTrue);
    expect(find.textContaining('Pre-poo: Oil'), findsOneWidget);
  });
}
