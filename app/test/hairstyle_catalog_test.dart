import 'package:flutter_test/flutter_test.dart';
import 'package:strandwise/models/hair_profile.dart';
import 'package:strandwise/services/hairstyle_recommender.dart';

List<String> _names(HairProfile p, Set<StyleGoal> g) =>
    HairstyleRecommender.recommend(
      p,
      g,
      limit: 200,
    ).map((i) => i.name).toList();

void main() {
  group('hairstyle catalog', () {
    test('names are unique and keep required entries', () {
      final names = HairstyleRecommender.allNames;
      expect(names.toSet().length, names.length);
      expect(names, containsAll(['Wash-and-go', 'Silk press', 'Silk wrap']));
      expect(names.length, 37);
    });

    test('every curl family has at least 8 styles', () {
      for (final f in ['1', '2', '3', '4']) {
        final n = _names(HairProfile(curlPattern: '${f}A'), {}).length;
        expect(n, greaterThanOrEqualTo(8), reason: 'family $f');
      }
    });

    test('every goal is covered', () {
      for (final g in StyleGoal.values) {
        final top = HairstyleRecommender.recommend(
          const HairProfile(curlPattern: '3B'),
          {g},
        );
        expect(top, isNotEmpty);
      }
    });

    test('tension styles are excluded for breakage and hair loss', () {
      for (final c in [HairConcern.breakage, HairConcern.hairLoss]) {
        final names = _names(HairProfile(curlPattern: '4C', concerns: {c}), {});
        for (final n in ['Box braids', 'Cornrows', 'Faux locs']) {
          expect(names, isNot(contains(n)));
        }
        expect(names, contains('Two-strand twists'));
      }
    });

    test('color-treated hair ranks Silk press lower', () {
      const plain = HairProfile(curlPattern: '3B');
      const colored = HairProfile(curlPattern: '3B', colorTreated: true);
      final goals = {StyleGoal.volume};
      expect(
        _names(colored, goals).indexOf('Silk press'),
        greaterThan(_names(plain, goals).indexOf('Silk press')),
      );
    });

    test('wig wearers get the wig install suggestion', () {
      const p = HairProfile(curlPattern: '3B', styling: {HairStyling.wigs});
      final top = HairstyleRecommender.recommend(p, {StyleGoal.protective});
      expect(top.map((i) => i.name), contains('Protective wig install'));
    });
  });
}
