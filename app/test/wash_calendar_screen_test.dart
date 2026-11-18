import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strandwise/data/wash_history_store.dart';
import 'package:strandwise/features/calendar/wash_calendar_screen.dart';
import 'package:strandwise/models/hair_profile.dart';
import 'package:strandwise/services/wash_insights.dart';
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

    await tester.tap(find.text('Dry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
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

    await tester.tap(find.text('Normal'));
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

  testWidgets('shows smart suggestions with disclaimer', (tester) async {
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
    await tester.scrollUntilVisible(
      find.text('Your wash-day insights'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Smart suggestions'), findsOneWidget);
    expect(find.textContaining('Not medical advice'), findsOneWidget);
    expect(find.textContaining('AI'), findsNothing);
  });

  testWidgets('insights card shows populated sections and hides empty ones', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: InsightsCard(
              insights: WashInsights(
                intervalDays: 5,
                summary: 'Wash about every 5 days.',
                scheduleNote: 'Based on your logs.',
                washDayPlan: ['Detangle first', 'Cleanse scalp'],
                practices: ['Use a microfiber towel'],
                productTips: ['Humectants'],
                avoid: ['Heavy silicones'],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Your wash-day plan'), findsOneWidget);
    expect(find.text('Detangle first'), findsOneWidget);
    expect(find.text('Practices to try'), findsOneWidget);
    expect(find.text('Products to look for'), findsOneWidget);
    expect(find.text('Go easy on'), findsOneWidget);
    expect(find.text('From your logs'), findsNothing);
    expect(find.text('Based on your logs.'), findsOneWidget);
    expect(find.textContaining('Not medical advice'), findsOneWidget);

    await tester.tap(find.text('Go easy on'));
    await tester.pumpAndSettle();
    expect(find.text('Heavy silicones'), findsOneWidget);
  });
}
