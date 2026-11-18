import 'package:flutter_test/flutter_test.dart';
import 'package:strandwise/models/hair_profile.dart';
import 'package:strandwise/models/wash_log.dart';
import 'package:strandwise/services/routine_engine.dart';
import 'package:strandwise/services/wash_insights.dart';

WashLog log(
  int day, {
  HairFeel? before,
  HairFeel? after,
  Set<HairStyling> styling = const {},
}) => WashLog(
  date: DateTime(2026, 11, day),
  products: const [],
  feelBefore: before,
  feelAfter: after,
  styling: styling,
);

void main() {
  const profile = HairProfile(curlPattern: '4C'); // base 7
  final base = RoutineEngine.washIntervalDays(profile);

  test('empty logs return default and ask for more logs', () {
    final r = WashInsightsEngine.analyze(profile, const []);
    expect(r.intervalDays, base);
    expect(r.summary, contains('Log a few more'));
  });

  test('old logs without feel fields are ignored', () {
    final r = WashInsightsEngine.analyze(profile, [log(1), log(2), log(3)]);
    expect(r.intervalDays, base);
    expect(r.summary, contains('Log a few more'));
  });

  test('single signal does not adjust', () {
    final r = WashInsightsEngine.analyze(profile, [
      log(1, before: HairFeel.dry),
    ]);
    expect(r.intervalDays, base);
  });

  test('repeated dry before lengthens interval', () {
    final r = WashInsightsEngine.analyze(profile, [
      for (var d = 1; d <= 3; d++) log(d, before: HairFeel.dry),
    ]);
    expect(r.intervalDays, base + 1);
    expect(r.summary, contains('dry before the last 3 washes'));
    expect(r.summary, contains('every ${base + 1} days'));
    expect(r.productTips.join(' '), contains('glycerin'));
  });

  test('repeated oily before shortens interval', () {
    final r = WashInsightsEngine.analyze(profile, [
      log(1, before: HairFeel.oily),
      log(2, before: HairFeel.oily),
    ]);
    expect(r.intervalDays, base - 1);
    expect(r.summary, contains('oily'));
  });

  test('dry after suggests moisture and lengthens', () {
    final r = WashInsightsEngine.analyze(profile, [
      log(1, after: HairFeel.dry),
      log(2, after: HairFeel.dry),
    ]);
    expect(r.intervalDays, base + 1);
    expect(r.practices.join(' '), contains('Deep condition'));
  });

  test('oily after gives clarify/rinse advice without changing interval', () {
    final r = WashInsightsEngine.analyze(profile, [
      log(1, after: HairFeel.oily),
      log(2, after: HairFeel.oily),
    ]);
    expect(r.intervalDays, base);
    expect(r.practices.join(' '), contains('Rinse thoroughly'));
    expect(r.productTips.join(' '), contains('lightweight'));
  });

  test('conflicting before signals cancel out', () {
    final r = WashInsightsEngine.analyze(profile, [
      log(1, before: HairFeel.dry),
      log(2, before: HairFeel.oily),
      log(3, before: HairFeel.dry),
      log(4, before: HairFeel.oily),
    ]);
    expect(r.intervalDays, base);
    expect(r.summary, contains('No clear pattern'));
  });

  test('only the five most recent feel logs count', () {
    final r = WashInsightsEngine.analyze(profile, [
      log(1, before: HairFeel.dry),
      log(2, before: HairFeel.dry),
      log(3, before: HairFeel.dry),
      for (var d = 4; d <= 8; d++) log(d, before: HairFeel.normal),
    ]);
    expect(r.intervalDays, base);
  });

  test('interval respects curl-pattern limits', () {
    final daily = WashInsightsEngine.analyze(
      const HairProfile(curlPattern: '4C', washFrequency: WashFrequency.daily),
      [log(1, before: HairFeel.oily), log(2, before: HairFeel.oily)],
    );
    expect(daily.intervalDays, 3); // coily: at most twice a week
    final biweekly = WashInsightsEngine.analyze(
      const HairProfile(
        curlPattern: '4C',
        washFrequency: WashFrequency.biweekly,
      ),
      [
        log(1, before: HairFeel.dry, after: HairFeel.dry),
        log(2, before: HairFeel.dry, after: HairFeel.dry),
      ],
    );
    expect(biweekly.intervalDays, 14);

    final straight = WashInsightsEngine.analyze(
      const HairProfile(
        curlPattern: '1A',
        washFrequency: WashFrequency.biweekly,
      ),
      [
        log(1, before: HairFeel.dry, after: HairFeel.dry),
        log(2, before: HairFeel.dry, after: HairFeel.dry),
      ],
    );
    expect(straight.intervalDays, 6); // looser: never a week unwashed
  });

  test('styling and profile add practices and tips', () {
    final r = WashInsightsEngine.analyze(
      const HairProfile(
        curlPattern: '4C',
        porosity: Porosity.low,
        concerns: {HairConcern.dandruff},
      ),
      [
        log(1, before: HairFeel.normal, styling: {HairStyling.braidsTwists}),
        log(2, before: HairFeel.normal, styling: {HairStyling.heatStyled}),
      ],
    );
    final all = [...r.practices, ...r.productTips].join(' ');
    expect(all, contains('protective styles'));
    expect(all, contains('heat protectant'));
    expect(all, contains('bond'));
    expect(all, contains('lightweight leave-in'));
    expect(all, contains('anti-dandruff'));
  });

  group('comprehensive suggestions', () {
    String joined(List<String> l) => l.join(' | ');

    test('every curl family gets plan, avoid and schedule note', () {
      for (final pat in ['1A', '2B', '3C', '4A']) {
        final r = WashInsightsEngine.analyze(HairProfile(curlPattern: pat), []);
        expect(r.washDayPlan, isNotEmpty, reason: pat);
        expect(r.avoid, isNotEmpty, reason: pat);
        expect(r.scheduleNote, contains(pat), reason: pat);
      }
      final straight = WashInsightsEngine.analyze(
        const HairProfile(curlPattern: '1B'),
        [],
      );
      expect(joined(straight.avoid), contains('full week'));
      expect(joined(straight.washDayPlan), isNot(contains('Pre-poo')));
      expect(straight.scheduleNote, contains('6 days'));
      final coily = WashInsightsEngine.analyze(
        const HairProfile(curlPattern: '4C'),
        [],
      );
      expect(joined(coily.avoid), contains('Daily shampooing'));
      expect(joined(coily.washDayPlan), contains('Pre-poo'));
      expect(joined(coily.practices), contains('bonnet'));
      expect(coily.scheduleNote, contains('twice a week'));
      final curly = WashInsightsEngine.analyze(
        const HairProfile(curlPattern: '3A'),
        [],
      );
      expect(joined(curly.avoid), contains('more than twice a week'));
    });

    test('wash plan follows porosity', () {
      final high = WashInsightsEngine.analyze(
        const HairProfile(curlPattern: '3B', porosity: Porosity.high),
        [],
      );
      expect(joined(high.washDayPlan), contains('LOC'));
      expect(joined(high.washDayPlan), contains('protein'));
      final low = WashInsightsEngine.analyze(
        const HairProfile(curlPattern: '3B', porosity: Porosity.low),
        [],
      );
      expect(joined(low.washDayPlan), contains('LCO'));
      expect(joined(low.avoid), contains('Heavy butters'));
    });

    test('hair loss and dandruff nudge toward a professional', () {
      final r = WashInsightsEngine.analyze(
        const HairProfile(curlPattern: '2A', concerns: {HairConcern.hairLoss}),
        [],
      );
      expect(joined(r.practices), contains('dermatologist'));
      expect(joined(r.practices), contains('not medical advice'));
    });

    test('dry before and oily after combine into scalp-only advice', () {
      final r = WashInsightsEngine.analyze(profile, [
        log(1, before: HairFeel.dry, after: HairFeel.oily),
        log(2, before: HairFeel.dry, after: HairFeel.oily),
      ]);
      expect(joined(r.practices), contains('dry before washing yet oily'));
    });

    test('normal before and after keeps routine', () {
      final r = WashInsightsEngine.analyze(profile, [
        log(1, before: HairFeel.normal, after: HairFeel.normal),
        log(2, before: HairFeel.normal, after: HairFeel.normal),
      ]);
      expect(joined(r.practices), contains('keep this routine'));
    });

    test('heat-styled dry washes suggest heat protectant', () {
      final r = WashInsightsEngine.analyze(profile, [
        log(
          1,
          before: HairFeel.normal,
          after: HairFeel.dry,
          styling: {HairStyling.heatStyled},
        ),
        log(
          2,
          before: HairFeel.normal,
          after: HairFeel.dry,
          styling: {HairStyling.heatStyled},
        ),
      ]);
      expect(joined(r.practices), contains('dry after heat-styled'));
    });

    test('oily before on wig washes suggests more scalp cleansing', () {
      final r = WashInsightsEngine.analyze(profile, [
        log(1, before: HairFeel.oily, styling: {HairStyling.wigs}),
        log(2, before: HairFeel.oily, styling: {HairStyling.braidsTwists}),
      ]);
      expect(joined(r.practices), contains('cleanse the scalp more often'));
    });

    test('product feedback highlights high and low ratings', () {
      WashLog rated(int day, Map<String, int> ratings) => WashLog(
        date: DateTime(2026, 11, day),
        products: ratings.keys.toList(),
        ratings: ratings,
      );
      final r = WashInsightsEngine.analyze(profile, [
        rated(1, {'Silk Mask': 9, 'Harsh Wash': 3}),
        rated(2, {'silk mask': 9, 'Harsh Wash': 4}),
        rated(3, {'Silk Mask': 9}),
      ]);
      expect(
        r.productFeedback.first,
        contains('Silk Mask averages 9/10 across 3 washes'),
      );
      expect(joined(r.productFeedback), contains('Harsh Wash averages'));
      expect(joined(r.productFeedback), contains('candidate to swap'));
      expect(joined(r.productFeedback), contains('No deep conditioner'));
    });

    test('no logs means no product feedback', () {
      expect(
        WashInsightsEngine.analyze(profile, const []).productFeedback,
        isEmpty,
      );
    });

    test('schedule note compares actual gaps with recommendation', () {
      final r = WashInsightsEngine.analyze(profile, [
        for (final d in [10, 12, 14, 16]) log(d),
      ]);
      expect(r.scheduleNote, contains('every 2 days'));
      expect(r.scheduleNote, contains('every 3–7 days is gentler'));
      final onTrack = WashInsightsEngine.analyze(profile, [
        for (final d in [1, 8, 15]) log(d),
      ]);
      expect(onTrack.scheduleNote, contains('right in line'));
      final straightLong = WashInsightsEngine.analyze(
        const HairProfile(curlPattern: '1A'),
        [log(1), log(10)],
      );
      expect(straightLong.scheduleNote, contains('at least every 6 days'));
    });

    test('lists are de-duplicated and capped', () {
      final r = WashInsightsEngine.analyze(
        const HairProfile(
          curlPattern: '4C',
          porosity: Porosity.high,
          strandSize: StrandSize.fine,
          scalp: ScalpType.oily,
          colorTreated: true,
          concerns: {HairConcern.breakage},
          styling: {
            HairStyling.heatStyled,
            HairStyling.braidsTwists,
            HairStyling.updos,
          },
        ),
        [
          for (var d = 1; d <= 5; d++)
            log(d, before: HairFeel.dry, after: HairFeel.dry),
        ],
      );
      for (final l in [
        r.practices,
        r.productTips,
        r.washDayPlan,
        r.avoid,
        r.productFeedback,
      ]) {
        expect(l.length, lessThanOrEqualTo(8));
        expect(l.toSet().length, l.length);
      }
      expect(r.practices.length, 8);
    });
  });
}
