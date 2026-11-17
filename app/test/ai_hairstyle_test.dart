import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strandwise/features/content/content_hub_screen.dart';
import 'package:strandwise/models/hair_profile.dart';
import 'package:strandwise/services/ai_assistant.dart';
import 'package:strandwise/services/hairstyle_recommender.dart';
import 'package:strandwise/theme/app_theme.dart';

class _FakeAi implements AiAssistant {
  @override
  bool get isAvailable => true;

  @override
  Future<AiAnswer> ask(String question, HairProfile profile) async =>
      const AiAnswer(
        text: 'Use a leave-in.',
        products: [
          AiProduct(
            name: 'Curl Cream',
            brand: 'Brand',
            sourceUrl: 'https://example.com/cream',
          ),
        ],
      );

  @override
  Future<List<HairstyleIdea>> hairstyles(
    HairProfile profile,
    Set<StyleGoal> goals,
  ) async => const [];
}

void main() {
  group('HairstyleRecommender', () {
    test('skips tension styles for breakage and respects curl family', () {
      const profile = HairProfile(
        curlPattern: '4C',
        concerns: {HairConcern.breakage},
      );
      final names = HairstyleRecommender.recommend(profile, {
        StyleGoal.protective,
      }, limit: 20).map((i) => i.name);
      expect(names, isNot(contains('Loose protective braids')));
      expect(names, isNot(contains('Air-dried waves')));
      expect(names, contains('Flat twists'));
    });

    test('ranks by chosen goals', () {
      const profile = HairProfile(curlPattern: '3B');
      final top = HairstyleRecommender.recommend(profile, {
        StyleGoal.definition,
      }).first;
      expect([
        'Wash-and-go',
        'Twist-out',
        'Braid-out',
        'Straw set',
      ], contains(top.name));
    });
  });

  testWidgets('Ask tab shows AI answer with cited product', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AskAnythingTab(
            profile: const HairProfile(curlPattern: '4C'),
            assistant: _FakeAi(),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'what for dry hair?');
    await tester.tap(find.byTooltip('Ask'));
    await tester.pumpAndSettle();

    expect(find.text('Use a leave-in.'), findsOneWidget);
    expect(find.text('Curl Cream'), findsOneWidget);
    expect(find.textContaining('example.com'), findsOneWidget);
  });
}
