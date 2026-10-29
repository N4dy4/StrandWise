import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:strandwise/features/onboarding/disclaimer_screen.dart';
import 'package:strandwise/features/profile/profile_screens.dart';
import 'package:strandwise/main.dart';
import 'package:strandwise/theme/app_theme.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const StrandWiseApp());

    expect(find.text('Welcome to StrandWise'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  test('Theme uses pink primary color (R1)', () {
    expect(AppTheme.light.colorScheme.primary, AppColors.pink);
    expect(AppTheme.light.scaffoldBackgroundColor, AppColors.blush);
  });

  testWidgets('Mockup support screens render', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: DisclaimerScreen(onDone: (_) {}),
    ));
    expect(find.text('Before we begin'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: SearchSourcesScreen()),
    ));
    expect(find.text('Ask anything'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: IngredientCheckScreen()),
    ));
    expect(find.text('Ingredient check'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const ProgressScreen(),
    ));
    expect(find.text('Progress'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const OfflineSyncScreen(),
    ));
    expect(find.text('Offline and sync'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const PrivacyScreen(),
    ));
    expect(find.text('Your privacy'), findsOneWidget);
  });
}
