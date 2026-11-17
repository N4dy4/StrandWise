import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strandwise/data/tutorial_repository.dart';
import 'package:strandwise/features/hairstyles/hairstyle_screen.dart';
import 'package:strandwise/models/hair_profile.dart';
import 'package:strandwise/models/tutorial.dart';
import 'package:strandwise/services/ai_assistant.dart';
import 'package:strandwise/services/hairstyle_recommender.dart';
import 'package:strandwise/theme/app_theme.dart';

HairstyleTutorial _t(String title, List<String> patterns) => HairstyleTutorial(
  styleName: 'x',
  title: title,
  sourceName: 'Chan',
  sourceUrl: 'https://youtu.be/$title',
  curlPatterns: patterns,
);

class _FakeRepo implements TutorialRepository {
  _FakeRepo(this.data);
  final Map<String, List<HairstyleTutorial>> data;
  var calls = 0;

  @override
  Future<Map<String, List<HairstyleTutorial>>> forStyles(
    List<String> styleNames,
  ) async {
    calls++;
    return data;
  }
}

class _NoAi implements AiAssistant {
  @override
  bool get isAvailable => false;
  @override
  Future<AiAnswer> ask(String q, HairProfile p) => throw UnimplementedError();
  @override
  Future<List<HairstyleIdea>> hairstyles(HairProfile p, Set<StyleGoal> g) =>
      throw UnimplementedError();
}

void main() {
  test('fromJson is defensive and unescapes entities', () {
    final t = HairstyleTutorial.fromJson({
      'style_name': 'Braids',
      'title': 'Mom&#39;s &amp; my braids',
      'source_url': 'https://a.b/c',
      'thumbnail_url': null,
      'curl_patterns': ['4'],
    });
    expect(t.title, "Mom's & my braids");
    expect(t.thumbnailUrl, '');
    expect(t.platform, 'youtube');
    expect(t.curlPatterns, ['4']);
    expect(HairstyleTutorial.fromJson({}).curlPatterns, isEmpty);
  });

  test('rankTutorials prefers family, then any, hides others', () {
    final ranked = rankTutorials([
      _t('any', []),
      _t('three', ['3']),
      _t('four', ['4']),
    ], '4C');
    expect(ranked.map((t) => t.title), ['four', 'any']);
  });

  test('youtubeSearchUri encodes style and family', () {
    expect(
      youtubeSearchUri('Twist out', '3B').toString(),
      'https://www.youtube.com/results?search_query=Twist+out+tutorial+curly+hair',
    );
  });

  Future<_FakeRepo> pump(WidgetTester tester, _FakeRepo repo) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HairstyleScreen(
            profile: const HairProfile(curlPattern: '4C'),
            assistant: _NoAi(),
            tutorials: repo,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('shows tutorial tiles and fallback link, one batched query', (
    tester,
  ) async {
    final name = HairstyleRecommender.recommend(
      const HairProfile(curlPattern: '4C'),
      {StyleGoal.lowMaintenance},
    ).first.name;
    final repo = await pump(
      tester,
      _FakeRepo({
        name: [
          _t('Fourc video', ['4']),
          _t('Other family', ['2']),
        ],
      }),
    );
    expect(repo.calls, 1);
    expect(find.text('Fourc video'), findsOneWidget);
    expect(find.text('Other family'), findsNothing);
    expect(find.text('Search how-to videos'), findsWidgets);
  });
}
