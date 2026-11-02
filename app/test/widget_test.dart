import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:strandwise/features/onboarding/disclaimer_screen.dart';
import 'package:strandwise/features/profile/profile_screens.dart';
import 'package:strandwise/main.dart';
import 'package:strandwise/theme/app_theme.dart';
import 'package:strandwise/widgets/mockup_bottom_navigation.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const StrandWiseApp());

    expect(find.text('StrandWise'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  test('Theme uses pink primary color (R1)', () {
    expect(AppTheme.light.colorScheme.primary, AppColors.pink);
    expect(AppTheme.light.scaffoldBackgroundColor, AppColors.blush);
  });

  testWidgets('Mockup support screens render', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DisclaimerScreen(onDone: (_) {}),
      ),
    );
    expect(find.text('Before we begin'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: SearchSourcesScreen()),
      ),
    );
    expect(find.text('Ask anything'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: IngredientCheckScreen()),
      ),
    );
    expect(find.text('Ingredient check'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ProgressScreen()),
    );
    expect(find.text('Progress'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const OfflineSyncScreen()),
    );
    expect(find.text('Offline and sync'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const PrivacyScreen()),
    );
    expect(find.text('Your privacy'), findsOneWidget);
  });

  testWidgets('Mockup navigation selects a destination', (
    WidgetTester tester,
  ) async {
    var selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            bottomNavigationBar: MockupBottomNavigation(
              currentIndex: selectedIndex,
              onSelected: (index) => setState(() => selectedIndex = index),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Profile'));
    await tester.pumpAndSettle();

    expect(selectedIndex, 4);
  });
}
