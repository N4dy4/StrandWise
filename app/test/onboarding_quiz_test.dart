import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strandwise/features/onboarding/onboarding_screen.dart';
import 'package:strandwise/models/hair_profile.dart';
import 'package:strandwise/services/routine_engine.dart';
import 'package:strandwise/theme/app_theme.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'quiz collects name, hair details, concern, color, washing, styling',
    (tester) async {
      HairProfile? result;
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: OnboardingScreen(onDone: (p) => result = p),
        ),
      );

      Future<void> next() async {
        await tester.pump();
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
      }

      expect(find.text('What should we call you?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '  Amara ');
      await tester.pump();
      await next();

      await tester.tap(find.text('Coily'));
      await tester.pump();
      await next();

      expect(find.text('How thick is each strand?'), findsOneWidget);
      expect(find.textContaining('square inch'), findsNothing);
      await tester.tap(find.text('Fine'));
      await next();

      await tester.tap(find.text('Thick'));
      await next();
      await next(); // scalp default

      expect(find.text("What's your biggest hair concern?"), findsOneWidget);
      await tester.tap(find.text('Breakage'));
      await tester.pump();
      await next();

      await tester.tap(find.text('Yes'));
      await next();

      await tester.tap(find.text('About once a week'));
      await next();

      await tester.tap(find.text('Braids / twists'));
      await next();
      await tester.pumpAndSettle();

      final p = result!;
      expect(p.name, 'Amara');
      expect(p.curlPattern, '4C');
      expect(p.strandSize, StrandSize.fine);
      expect(p.density, Density.thick);
      expect(p.concerns, {HairConcern.breakage});
      expect(p.colorTreated, isTrue);
      expect(p.washFrequency, WashFrequency.weekly);
      expect(p.styling, {HairStyling.braidsTwists});
      expect(RoutineEngine.washIntervalDays(p), 7);
    },
  );

  test('profiles saved before the new fields still load', () {
    final p = HairProfile.fromJson({
      'curlPattern': '3B',
      'porosity': 'low',
      'density': 'thin',
      'scalp': 'oily',
      'concerns': ['frizz'],
    });
    expect(p.name, '');
    expect(p.colorTreated, isFalse);
    expect(p.washFrequency, isNull);
    expect(p.strandSize, StrandSize.medium);
    final q = HairProfile.decode(
      const HairProfile(
        curlPattern: '2A',
        name: 'Lea',
        colorTreated: true,
        washFrequency: WashFrequency.daily,
        styling: {HairStyling.wigs},
      ).encode(),
    );
    expect(q.name, 'Lea');
    expect(q.washFrequency, WashFrequency.daily);
    expect(q.styling, {HairStyling.wigs});
  });
}
