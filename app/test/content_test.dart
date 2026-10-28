import 'package:flutter_test/flutter_test.dart';
import 'package:strandwise/models/content_item.dart';
import 'package:strandwise/models/hair_profile.dart';
import 'package:strandwise/models/product.dart';
import 'package:strandwise/services/content_ranker.dart';
import 'package:strandwise/services/ingredient_flagger.dart';

ContentItem item(String id,
        {Set<String> curl = const {}, Set<HairConcern> concerns = const {}}) =>
    ContentItem(
      id: id,
      type: ContentType.article,
      title: id,
      sourceName: 's',
      sourceUrl: 'https://example.com',
      curlPatterns: curl,
      concerns: concerns,
    );

void main() {
  group('IngredientFlagger', () {
    test('flags sulfates, silicones, drying alcohols', () {
      final f = IngredientFlagger.flag([
        'Sodium Lauryl Sulfate',
        'Ammonium Laureth Sulfate',
        'Dimethicone',
        'Amodimethicone',
        'Alcohol Denat.',
      ]);
      expect(f[IngredientFlag.sulfate], hasLength(2));
      expect(f[IngredientFlag.silicone], hasLength(2));
      expect(f[IngredientFlag.dryingAlcohol], ['Alcohol Denat.']);
    });

    test('does not flag fatty alcohols or magnesium sulfate', () {
      expect(IngredientFlagger.flag(
          ['Cetyl Alcohol', 'Cetearyl Alcohol', 'Magnesium Sulfate', 'Glycerin']),
          isEmpty);
    });
  });

  group('ContentRanker', () {
    const profile = HairProfile(
        curlPattern: '4B', concerns: {HairConcern.breakage});

    test('excludes other curl patterns and ranks by match', () {
      final ranked = ContentRanker.rank([
        item('all'),
        item('wavy', curl: {'2'}),
        item('family', curl: {'4'}),
        item('exact', curl: {'4B'}),
        item('concern', concerns: {HairConcern.breakage}),
      ], profile);
      expect(ranked.map((i) => i.id), ['exact', 'family', 'concern', 'all']);
    });
  });

  test('ContentItem.fromJson keeps source_url', () {
    final i = ContentItem.fromJson({
      'id': '1',
      'type': 'video',
      'title': 't',
      'source_name': 'n',
      'source_url': 'https://x.test',
      'concerns': ['frizz'],
    });
    expect(i.sourceUrl, 'https://x.test');
    expect(i.concerns, {HairConcern.frizz});
  });
}
