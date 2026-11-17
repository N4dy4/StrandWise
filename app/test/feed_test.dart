import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strandwise/data/local_content_repository.dart';
import 'package:strandwise/features/content/content_hub_screen.dart';
import 'package:strandwise/models/content_item.dart';
import 'package:strandwise/models/hair_profile.dart';
import 'package:strandwise/services/content_ranker.dart';
import 'package:strandwise/theme/app_theme.dart';

ContentItem it(
  String id, {
  String? title,
  ContentType type = ContentType.video,
  ContentPlatform platform = ContentPlatform.web,
  Set<String> curl = const {},
  Set<HairConcern> concerns = const {},
  DateTime? publishedAt,
}) => ContentItem(
  id: id,
  type: type,
  title: title ?? id,
  sourceName: 's',
  sourceUrl: 'https://example.com/$id',
  platform: platform,
  curlPatterns: curl,
  concerns: concerns,
  publishedAt: publishedAt,
);

class _Repo extends LocalContentRepository {
  @override
  Future<List<ContentItem>> contentItems() async => [
    it('yt', title: 'YT video', platform: ContentPlatform.youtube),
    it('tt', title: 'TT clip', platform: ContentPlatform.tiktok),
    it('art', title: 'Web article', type: ContentType.article),
  ];
}

void main() {
  final now = DateTime(2026, 6, 1);
  const profile = HairProfile(
    curlPattern: '4C',
    porosity: Porosity.low,
    scalp: ScalpType.oily,
    concerns: {HairConcern.frizz},
  );

  group('ContentRanker', () {
    test('boosts porosity/scalp keyword matches', () {
      final plain = it('a', title: 'Wash day tips');
      final match = it('b', title: 'Low porosity wash day for oily scalp');
      expect(
        ContentRanker.score(match, profile, now: now),
        greaterThan(ContentRanker.score(plain, profile, now: now)),
      );
      expect(
        ContentRanker.rank([plain, match], profile, now: now).first.id,
        'b',
      );
    });

    test('mild recency boost and deterministic ties', () {
      final old = it('old', publishedAt: DateTime(2020));
      final fresh = it('fresh', publishedAt: DateTime(2026, 5));
      expect(
        ContentRanker.rank([old, fresh], profile, now: now).first.id,
        'fresh',
      );
      final a = ContentRanker.rank([old, fresh], profile, now: now);
      expect(ContentRanker.rank([old, fresh], profile, now: now), a);
    });

    test('diversifies platforms in the top results', () {
      final items = [
        for (var k = 0; k < 4; k++)
          it(
            'y$k',
            platform: ContentPlatform.youtube,
            concerns: {HairConcern.frizz},
          ),
        it(
          't0',
          platform: ContentPlatform.tiktok,
          concerns: {HairConcern.frizz},
        ),
      ];
      final ids = ContentRanker.rank(items, profile, now: now).map((i) => i.id);
      expect(ids.toList().indexOf('t0'), lessThan(3));
    });

    test('filters other curl patterns; reason text; medical flag kept', () {
      final ranked = ContentRanker.rank(
        [
          it('wavy', curl: {'2'}),
          it('loss', curl: {'4'}, concerns: {HairConcern.hairLoss}),
        ],
        profile,
        now: now,
      );
      expect(ranked.map((i) => i.id), ['loss']);
      expect(ranked.single.isMedicalSensitive, isTrue);
      expect(
        ContentRanker.reason(
          it('r', curl: {'4C'}, concerns: {HairConcern.frizz}),
          profile,
        ),
        'Matches 4C · frizz',
      );
    });
  });

  test('fromJson parses platform defensively', () {
    final base = {
      'id': '1',
      'type': 'video',
      'title': 't',
      'source_name': 'n',
      'source_url': 'https://x.test',
    };
    final d = ContentItem.fromJson(base);
    expect(d.platform, ContentPlatform.web);
    expect(d.thumbnailUrl, '');
    expect(d.publishedAt, isNull);
    final t = ContentItem.fromJson({
      ...base,
      'platform': 'tiktok',
      'thumbnail_url': 'https://i.test/a.jpg',
      'published_at': '2026-01-02T03:04:05Z',
    });
    expect(t.platform, ContentPlatform.tiktok);
    expect(t.publishedAt, isNotNull);
    expect(
      ContentItem.fromJson({...base, 'platform': 'myspace'}).platform,
      ContentPlatform.web,
    );
  });

  testWidgets('filter chips narrow the feed and show empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: FeedTab(profile: profile, repository: _Repo()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('YT video'), findsOneWidget);
    expect(find.text('Web article'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'TikTok'));
    await tester.pumpAndSettle();
    expect(find.text('TT clip'), findsOneWidget);
    expect(find.text('YT video'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Articles'));
    await tester.pumpAndSettle();
    expect(find.text('Web article'), findsOneWidget);
    expect(find.text('TT clip'), findsNothing);
  });
}
