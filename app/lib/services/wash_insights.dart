import '../models/hair_profile.dart';
import '../models/wash_log.dart';
import 'routine_engine.dart';

class WashInsights {
  const WashInsights({
    required this.intervalDays,
    required this.summary,
    this.practices = const [],
    this.productTips = const [],
    this.washDayPlan = const [],
    this.avoid = const [],
    this.productFeedback = const [],
    this.scheduleNote = '',
  });

  /// Recommended days between washes, adjusted by logged history.
  final int intervalDays;

  /// One-line explanation of why the schedule is what it is.
  final String summary;
  final List<String> practices;

  /// Product types / ingredients to look for (not specific brands).
  final List<String> productTips;

  /// Ordered wash-day steps tailored to curl pattern, porosity, scalp, etc.
  final List<String> washDayPlan;

  /// Habits/ingredients to go easy on for this hair.
  final List<String> avoid;

  /// Notes from the user's own product ratings and usage in logged washes.
  final List<String> productFeedback;

  /// Explains the curl-pattern limits (looser: <7 days; curly/coily: <=2x/week)
  /// and the gap between recommended and actual logged washes.
  final String scheduleNote;
}

abstract final class WashInsightsEngine {
  static const _window = 5;
  static const _minSignals = 2;

  /// Rule-based (v1, no ML): adjusts the routine interval from recent logs.
  static WashInsights analyze(HairProfile profile, List<WashLog> logs) {
    final base = RoutineEngine.washIntervalDays(profile);
    final recent = ([
      for (final l in logs)
        if (l.feelBefore != null || l.feelAfter != null) l,
    ]..sort((a, b) => b.date.compareTo(a.date))).take(_window).toList();

    int count(HairFeel? Function(WashLog) pick, HairFeel feel) =>
        recent.where((l) => pick(l) == feel).length;
    final dryBefore = count((l) => l.feelBefore, HairFeel.dry);
    final oilyBefore = count((l) => l.feelBefore, HairFeel.oily);
    final dryAfter = count((l) => l.feelAfter, HairFeel.dry);
    final oilyAfter = count((l) => l.feelAfter, HairFeel.oily);

    final drynessBefore = dryBefore >= _minSignals && dryBefore > oilyBefore;
    final oilinessBefore = oilyBefore >= _minSignals && oilyBefore > dryBefore;
    final drynessAfter = dryAfter >= _minSignals && dryAfter > oilyAfter;
    final oilinessAfter = oilyAfter >= _minSignals && oilyAfter > dryAfter;

    var delta = 0;
    if (oilinessBefore) delta -= 1;
    if (drynessBefore) delta += 1;
    if (drynessAfter) delta += 1;
    final (lo, hi) = RoutineEngine.washIntervalBounds(profile);
    final interval = (base + delta).clamp(lo, hi);

    final parts = <String>[];
    if (oilinessBefore) {
      parts.add('felt oily before the last $oilyBefore washes');
    }
    if (drynessBefore) parts.add('felt dry before the last $dryBefore washes');
    if (drynessAfter) parts.add('still felt dry after $dryAfter recent washes');
    if (oilinessAfter) {
      parts.add('still felt oily after $oilyAfter recent washes');
    }

    final String summary;
    if (recent.length < _minSignals) {
      summary =
          'Log a few more washes with how your hair felt before and after, '
          'and we\'ll fine-tune your schedule. For now: every $base days.';
    } else if (parts.isEmpty) {
      summary =
          'No clear pattern in your recent washes, so we\'re keeping wash day '
          'at every $interval days.';
    } else {
      final why = 'Your hair has ${parts.join(' and ')}';
      if (interval > base) {
        summary = '$why, so we moved wash day to every $interval days.';
      } else if (interval < base) {
        summary = '$why, so we moved wash day to every $interval days.';
      } else {
        summary =
            '$why. We\'re keeping wash day at every $interval days '
            'and adjusting your routine instead.';
      }
    }

    final sorted = [...logs]..sort((a, b) => b.date.compareTo(a.date));
    final c = _Ctx(
      profile: profile,
      recent: recent,
      allLogs: sorted,
      dryBefore: dryBefore >= _minSignals,
      oilyBefore: oilyBefore >= _minSignals,
      dryAfter: dryAfter >= _minSignals,
      oilyAfter: oilyAfter >= _minSignals,
      normalBefore: count((l) => l.feelBefore, HairFeel.normal) >= _minSignals,
      normalAfter: count((l) => l.feelAfter, HairFeel.normal) >= _minSignals,
      drynessBefore: drynessBefore,
      oilinessBefore: oilinessBefore,
      drynessAfter: drynessAfter,
      oilinessAfter: oilinessAfter,
    );

    return WashInsights(
      intervalDays: interval,
      summary: summary,
      practices: _practices(c),
      productTips: _tips(c),
      washDayPlan: _plan(c),
      avoid: _avoid(c),
      productFeedback: _feedback(c),
      scheduleNote: _scheduleNote(c, interval),
    );
  }

  // ---- practices ----------------------------------------------------------

  static List<String> _practices(_Ctx c) {
    final b = _Bag();
    final p = c.profile;

    // Signals from the user's own logs first.
    if (c.oilinessBefore) {
      b.add('Focus shampoo on the scalp and massage with fingertips.');
    }
    if (c.drynessBefore) {
      b.add('Refresh between washes with a light water mist and seal.');
    }
    if (c.drynessAfter) {
      b.add('Deep condition each wash day and keep cleansing gentle.');
      b.add('Apply conditioner to soaking-wet hair, mid-lengths to ends.');
    }
    if (c.oilinessAfter) {
      b.add('Rinse thoroughly so no residue is left on the scalp.');
      b.add('Keep conditioner off the scalp.');
    }
    if (c.dryBefore && c.oilyAfter) {
      b.add(
        'Hair feels dry before washing yet oily after: cleanse only the '
        'scalp, rinse well, and use less product, keeping heavy products '
        'to the ends.',
      );
    }
    if (c.dryBefore && c.dryAfter) {
      b.add(
        'Hair feels dry both before and after washing: switch to a gentler '
        'cleanser and add a moisture-focused deep treatment.',
      );
    }
    if (c.dryBefore && c.oilyBefore) {
      b.add(
        'Your logs are mixed (dry some days, oily others): treat the scalp '
        'and the lengths separately; cleanse roots, moisturize ends.',
      );
    }
    if (c.normalBefore && c.normalAfter) {
      b.add('Hair feels balanced before and after washing: keep this routine.');
    }
    if (c.heatDryAfter) {
      b.add(
        'Hair felt dry after heat-styled washes: use a heat protectant every '
        'time, lower the temperature and heat-style less often.',
      );
    }
    if (c.protectiveOilyBefore) {
      b.add(
        'Your scalp felt oily before washes after braids, wigs or updos: '
        'cleanse the scalp more often (diluted shampoo with a nozzle tip) '
        'instead of leaving it for weeks.',
      );
    }
    if (c.trend < 0) {
      b.add(
        'Hair has felt drier after recent washes than earlier ones; review '
        'any recent product, water or heat changes.',
      );
    }

    // Concerns.
    if (p.concerns.contains(HairConcern.dandruff)) {
      b.add(
        'Leave anti-dandruff shampoo on the scalp for the time on the label; '
        'if flaking or itching persists, see a doctor or dermatologist.',
      );
    }
    if (p.concerns.contains(HairConcern.hairLoss)) {
      b.add(
        'For hair loss, keep styles loose and scalp care gentle, and see a '
        'doctor or dermatologist to find the cause. This is not medical '
        'advice.',
      );
    }
    if (p.concerns.contains(HairConcern.breakage)) {
      b.add('Detangle only when hair is wet and conditioned.');
    }
    if (p.concerns.contains(HairConcern.frizz)) {
      b.add(
        'Avoid touching hair while it dries; apply styler to wet hair and '
        'don\'t rough-towel.',
      );
    }
    if (p.concerns.contains(HairConcern.dryness)) {
      b.add('Moisturize damp hair, then seal, on days between washes.');
    }

    // Styling.
    if (c.protective) {
      b.add(
        'Under protective styles, cleanse the scalp regularly '
        'but avoid over-washing the lengths.',
      );
      b.add(
        'Keep protective styles loose at the roots; tight or painful '
        'tension can damage follicles, and styles shouldn\'t stay in too '
        'long.',
      );
      b.add(
        'On take-down, detangle gently with conditioner and do a deep '
        'treatment before the next wash.',
      );
    }
    if (c.styles.contains(HairStyling.heatStyled)) {
      b.add(
        'Apply heat protectant before every heat session and '
        'keep heat on the lowest effective setting.',
      );
    }
    if (c.styles.contains(HairStyling.updos)) {
      b.add('Vary where you place buns and ponytails, and use snag-free ties.');
    }

    // Pattern and baseline care.
    if (c.curlyOrCoily) {
      b.add(
        'Curly and coily hair stays moisturized when washed no more than '
        'twice a week; refresh with water and leave-in in between.',
      );
      b.add(
        'Protect hair at night with a satin bonnet, scarf or pillowcase, '
        'or a loose pineapple/twist.',
      );
      b.add(
        'Detangle gently in sections with fingers or a wide-tooth comb, '
        'ideally with conditioner and from the ends up.',
      );
      if (c.fam == 4) {
        b.add(
          'Coily strands are the most fragile: keep manipulation low and '
          'moisturize often.',
        );
      }
    } else {
      b.add(
        'Looser patterns get oily faster, so try not to go a full week '
        'without washing.',
      );
      b.add(
        'Protect hair at night with a silk or satin pillowcase, or a loose '
        'braid, to reduce friction.',
      );
      if (c.fam == 1 || (c.fam == 2 && c.sub == 'A')) {
        b.add(
          'Straighter hair shows oil quickly; avoid touching the roots '
          'and brush gently from the ends.',
        );
      }
    }
    if (p.scalp == ScalpType.dry) {
      b.add('Gently massage the scalp to spread natural oils.');
    } else if (p.scalp == ScalpType.oily) {
      b.add('Massage the scalp for a couple of minutes while shampooing.');
    }
    if (p.colorTreated) {
      b.add(
        'Wash color-treated hair with cooler water and space washes out '
        'to keep color and moisture.',
      );
    }
    if (p.strandSize == StrandSize.fine || p.density == Density.thin) {
      b.add(
        'Handle fine or thin hair gently; skip tight styles and rough brushing.',
      );
    }
    b.add(
      p.concerns.contains(HairConcern.breakage) || p.colorTreated
          ? 'Trim every 8–12 weeks to remove split ends before they travel up.'
          : 'Trim every 3–4 months, or when ends look thin or split.',
    );
    if (b.items.isEmpty) {
      b.add('Keep logging how your hair feels before and after washing.');
    }
    return b.top();
  }

  // ---- product tips -------------------------------------------------------

  static List<String> _tips(_Ctx c) {
    final b = _Bag();
    final p = c.profile;

    if (c.oilinessBefore) {
      b.add('a gentle clarifying or scalp-balancing cleanser');
    }
    if (c.drynessBefore) {
      b.add('humectants like glycerin or aloe, sealed with a light oil');
    }
    if (c.drynessAfter) {
      b.add('a rich conditioner or deep conditioner with butters and oils');
      b.add('a low-lather, sulfate-free cleanser');
    }
    if (c.oilinessAfter) {
      b.add('a lightweight, water-based conditioner');
      b.add('a clarifying shampoo once every few weeks');
    }
    if (p.concerns.contains(HairConcern.dandruff)) {
      b.add('a gentle anti-dandruff shampoo (e.g. zinc or ketoconazole)');
    }
    if (p.concerns.contains(HairConcern.hairLoss)) {
      b.add(
        'a gentle, scalp-friendly shampoo; check with a doctor before '
        'using any hair-growth treatment',
      );
    }
    if (c.protective) {
      b.add('a diluted, nozzle-tip scalp cleanser or light scalp oil');
    }
    if (c.styles.contains(HairStyling.heatStyled) || c.heatDryAfter) {
      b.add('a heat protectant spray or cream');
      b.add('a weekly bond-building or moisture treatment');
    }
    if (p.concerns.contains(HairConcern.breakage)) {
      b.add('a protein or bond-strengthening treatment, used sparingly');
    }
    if (p.concerns.contains(HairConcern.dryness) && !c.drynessAfter) {
      b.add('humectants like glycerin plus a rich leave-in');
    }
    if (p.concerns.contains(HairConcern.frizz)) {
      b.add('a curl cream or gel with film-forming humectants');
    }
    if (p.colorTreated) b.add('a color-safe, sulfate-free shampoo');

    switch (p.porosity) {
      case Porosity.high:
        b.add('leave-in with sealing oils or butters to hold moisture');
        b.add(
          'a protein-balanced conditioner to help fill gaps in the cuticle',
        );
      case Porosity.low:
        b.add(
          'a lightweight leave-in; use heat or steam to help products absorb',
        );
        b.add('light oils (jojoba, grapeseed) rather than heavy butters');
      case Porosity.medium:
        break;
    }
    switch (c.fam) {
      case 1:
        b.add('a lightweight volumizing or balancing shampoo and a mousse');
      case 2:
        b.add('a lightweight mousse or wave-enhancing gel');
        b.add('a lightweight conditioner focused on the ends');
      case 3:
        b.add('a curl-defining cream and a gel for hold');
        b.add('a moisturizing, sulfate-free shampoo or co-wash');
      default:
        b.add('a rich cream or butter-based moisturizer to seal in water');
        b.add('a moisturizing, sulfate-free shampoo or co-wash');
        b.add('a thick, slip-rich conditioner for detangling');
    }
    if (p.strandSize == StrandSize.fine || p.density == Density.thin) {
      b.add('lightweight, water-based products so hair isn\'t weighed down');
    } else if (p.strandSize == StrandSize.coarse ||
        p.density == Density.thick) {
      b.add('richer creams and butters, applied in small sections');
    }
    if (p.scalp == ScalpType.oily) {
      b.add('a balancing shampoo with salicylic acid or tea tree');
    } else if (p.scalp == ScalpType.dry) {
      b.add(
        'a lightly moisturizing, gentle cleanser and a few drops of scalp oil',
      );
    }
    b.add('a satin bonnet or pillowcase for night');
    return b.top();
  }

  // ---- wash-day plan ------------------------------------------------------

  static List<String> _plan(_Ctx c) {
    final p = c.profile;
    final plan = <String>[];
    final dry =
        p.concerns.contains(HairConcern.dryness) ||
        c.drynessBefore ||
        c.drynessAfter;
    final breakage = p.concerns.contains(HairConcern.breakage);
    final oilyScalp =
        p.scalp == ScalpType.oily ||
        c.oilinessBefore ||
        p.concerns.contains(HairConcern.dandruff);
    final lowP = p.porosity == Porosity.low;
    final highP = p.porosity == Porosity.high;
    final lightHair =
        p.strandSize == StrandSize.fine || p.density == Density.thin;
    final heavyHair =
        p.strandSize == StrandSize.coarse || p.density == Density.thick;

    if (c.curlyOrCoily || breakage || dry || p.colorTreated) {
      final oil = lowP || lightHair
          ? 'a lightweight oil (like jojoba or grapeseed) or a little conditioner'
          : 'an oil (like coconut, olive or avocado) or a conditioner';
      plan.add(
        'Pre-poo: smooth $oil through dry hair for 15–30 minutes'
        '${c.curlyOrCoily ? ', finger-detangling gently in sections' : ''} '
        'to cushion the strands before cleansing.',
      );
    }

    if (oilyScalp) {
      plan.add(
        'Cleanse: shampoo the scalp only, massaging with fingertips for '
        'about two minutes; let the suds rinse down the lengths. '
        '${p.concerns.contains(HairConcern.dandruff) ? 'Leave an anti-dandruff shampoo on for the time on the label. ' : ''}'
        'Rinse thoroughly.',
      );
    } else if (c.curlyOrCoily || dry || p.colorTreated) {
      plan.add(
        'Cleanse gently: a low-lather, sulfate-free shampoo on the scalp '
        'in sections, letting the suds rinse down the lengths.',
      );
    } else {
      plan.add(
        'Cleanse: shampoo the scalp, avoiding rough scrubbing of the '
        'lengths; one lather is usually enough.',
      );
    }

    if (c.fam == 4) {
      plan.add(
        'Cadence: co-wash or use a very gentle cleanser between shampoos, '
        'and clarify every 4–6 weeks (sooner if you build up product or '
        'wear protective styles).',
      );
    } else if (c.fam == 3) {
      plan.add(
        'Cadence: alternate shampoo and co-wash washes, and clarify every '
        '3–4 weeks, or sooner with heavy products or hard water.',
      );
    } else {
      plan.add(
        'Cadence: shampoo each wash day and clarify every 2–4 weeks if '
        'you use styling products; skip co-washing if your roots get oily.',
      );
    }

    plan.add(
      'Condition: ${highP || p.strandSize == StrandSize.coarse || dry
          ? 'a rich, slippery conditioner'
          : lowP || lightHair
          ? 'a lightweight conditioner'
          : 'a medium-weight conditioner'} '
      'on soaking-wet mid-lengths to ends'
      '${lightHair
          ? ' (a small amount, kept off the roots)'
          : heavyHair
          ? ' in small sections so it reaches every strand'
          : ''}'
      '${lowP
          ? ', with warm water or a shower cap to help it absorb'
          : highP
          ? ', rinsing with cool water to help seal the cuticle'
          : ''}. '
      'Detangle with fingers or a wide-tooth comb from the ends up.',
    );

    final proteinRisk =
        breakage ||
        highP ||
        p.colorTreated ||
        c.styles.contains(HairStyling.heatStyled);
    if (proteinRisk) {
      plan.add(
        'Deep treatment: alternate a moisture mask and a protein or '
        'bond-repair treatment, each about every 2–4 washes. '
        '${dry ? 'If hair feels dry or brittle, lean on moisture first and use protein sparingly.' : 'If hair feels mushy or limp use more protein; if stiff or straw-like, use more moisture.'}',
      );
    } else if (c.curlyOrCoily || dry) {
      plan.add(
        'Deep treatment: a moisturizing deep conditioner every 1–2 washes '
        '(about 15–30 minutes, with gentle heat if you can).',
      );
    } else {
      plan.add(
        'Deep treatment: a moisture mask every 2–4 weeks, or when ends feel '
        'rough.',
      );
    }

    if (highP) {
      plan.add(
        'Leave-in and seal (LOC): liquid or leave-in, then oil, then cream '
        'to lock moisture in.',
      );
    } else if (lowP) {
      plan.add(
        'Leave-in and seal (LCO): a light liquid leave-in, then a cream, '
        'then a few drops of light oil; skip heavy butters.',
      );
    } else if (c.curlyOrCoily) {
      plan.add(
        'Leave-in and seal (LOC or LCO): leave-in, cream, then a light oil '
        'on the ends.',
      );
    } else {
      plan.add(
        'Leave-in: a lightweight leave-in or mist on the lengths, nothing '
        'on the roots.',
      );
    }

    if (c.protective) {
      plan.add(
        'Style: before installing braids, twists, a wig or an updo, make '
        'sure hair is fully dry and moisturized and keep the roots loose.',
      );
    } else if (c.fam == 4) {
      plan.add(
        'Style: apply cream and gel in small sections for twist-outs or '
        'wash-and-gos.',
      );
    } else if (c.fam == 3) {
      plan.add(
        'Style: rake or scrunch gel into soaking-wet hair, then leave it '
        'alone until it\'s dry.',
      );
    } else {
      plan.add(
        'Style: a lightweight mousse or cream, applied at the mid-lengths '
        'and ends.',
      );
    }

    final heat = c.styles.contains(HairStyling.heatStyled);
    plan.add(
      c.curlyOrCoily
          ? 'Dry: blot with a microfiber towel or cotton t-shirt (plop for '
                '10–20 minutes), then air dry or diffuse on low heat.'
                '${heat ? ' Use heat protectant before any heat.' : ''}'
          : 'Dry: blot gently and air dry or use a low-heat blow-dry.'
                '${heat ? ' Always use a heat protectant first.' : ''}',
    );
    return plan.take(_cap).toList();
  }

  // ---- avoid --------------------------------------------------------------

  static List<String> _avoid(_Ctx c) {
    final b = _Bag();
    final p = c.profile;
    if (c.oilinessBefore || c.oilinessAfter) {
      b.add('Piling conditioner or heavy oils onto the scalp.');
    }
    if (p.concerns.contains(HairConcern.hairLoss) || c.protective) {
      b.add('Tight styles that pull on the hairline or scalp.');
    }
    if (c.fam == 4) {
      b.add('Daily shampooing, which strips coily hair of moisture.');
    } else if (c.fam == 3) {
      b.add('Washing more than twice a week.');
    } else {
      b.add(
        'Going a full week without washing; it lets oil and buildup stack up.',
      );
    }
    if (p.concerns.contains(HairConcern.dryness) ||
        p.colorTreated ||
        c.drynessBefore ||
        c.drynessAfter ||
        c.fam == 4) {
      b.add('Harsh sulfate cleansers and very hot water.');
    }
    if (p.porosity == Porosity.low ||
        p.strandSize == StrandSize.fine ||
        p.density == Density.thin) {
      b.add('Heavy butters and thick oils that weigh hair down or sit on top.');
    }
    if (p.concerns.contains(HairConcern.dryness) ||
        c.dryBefore ||
        c.dryAfter ||
        (p.concerns.contains(HairConcern.breakage) && c.fam >= 3)) {
      b.add(
        'Too much protein if hair feels dry or brittle; balance with moisture.',
      );
    }
    if (p.concerns.contains(HairConcern.breakage)) {
      b.add('Detangling dry hair or rough towel drying.');
    }
    if (c.styles.contains(HairStyling.heatStyled) || c.heatDryAfter) {
      b.add('Frequent high heat without a heat protectant.');
    }
    if (p.porosity == Porosity.high || p.colorTreated) {
      b.add('Over-clarifying, which can leave porous or colored hair rough.');
    } else {
      b.add('Over-clarifying; once or twice a month is enough for most hair.');
    }
    if (c.protective) {
      b.add(
        'Leaving protective styles in too long or skipping take-down care.',
      );
    }
    if (p.concerns.contains(HairConcern.dandruff)) {
      b.add('Scratching or scrubbing flakes, which can irritate the scalp.');
    }
    return b.top();
  }

  // ---- product feedback ---------------------------------------------------

  static List<String> _feedback(_Ctx c) {
    final b = _Bag();
    final logs = c.allLogs;
    if (logs.isEmpty) return const [];

    final scores = <String, List<int>>{};
    final names = <String, String>{};
    for (final l in logs) {
      for (final e in l.ratings.entries) {
        final k = e.key.trim().toLowerCase();
        if (k.isEmpty) continue;
        names.putIfAbsent(k, () => e.key.trim());
        scores.putIfAbsent(k, () => []).add(e.value);
      }
    }
    String avg(List<int> v) {
      final a = v.reduce((x, y) => x + y) / v.length;
      return (a - a.roundToDouble()).abs() < 0.05
          ? a.round().toString()
          : a.toStringAsFixed(1);
    }

    double mean(List<int> v) => v.reduce((x, y) => x + y) / v.length;
    final byAvg = scores.keys.toList()
      ..sort((a, b) => mean(scores[b]!).compareTo(mean(scores[a]!)));
    for (final k in byAvg) {
      final v = scores[k]!;
      if (mean(v) >= 8) {
        b.add(
          v.length == 1
              ? '${names[k]} got ${v.first}/10 — keep it in the rotation.'
              : '${names[k]} averages ${avg(v)}/10 across ${v.length} washes — keep it.',
        );
      }
    }
    for (final k in byAvg.reversed) {
      final v = scores[k]!;
      if (mean(v) <= 4) {
        b.add(
          v.length == 1
              ? '${names[k]} got ${v.first}/10 — a candidate to swap for a '
                    'different formula.'
              : '${names[k]} averages ${avg(v)}/10 across ${v.length} washes — a candidate to swap.',
        );
      }
    }
    if (logs.length >= 2 && scores.isEmpty) {
      b.add('Rate the products you use (1–10) to see which ones to keep.');
    }

    if (logs.length >= 3) {
      final p = c.profile;
      final n = logs.length;
      final deep = logs
          .where((l) => (l.deepConditioner ?? '').isNotEmpty)
          .length;
      final prePoo = logs.where((l) => l.didPrePoo).length;
      final drynessNeed =
          p.concerns.contains(HairConcern.dryness) ||
          c.dryBefore ||
          c.dryAfter ||
          p.porosity == Porosity.high;
      if (deep == 0 && (drynessNeed || c.curlyOrCoily)) {
        b.add(
          'No deep conditioner logged in your last $n washes; '
          '${drynessNeed ? 'for dry hair' : 'for curly and coily hair'} '
          'a weekly or biweekly deep treatment can help.',
        );
      }
      if (logs.every((l) => (l.shampoo ?? '').isEmpty) &&
          logs.any((l) => l.products.isNotEmpty)) {
        b.add('No shampoo or cleanser logged; log it to track what works.');
      }
      if (logs.every((l) => l.styleProducts.isEmpty) &&
          (p.concerns.contains(HairConcern.frizz) || c.curlyOrCoily)) {
        b.add(
          'No styling products logged; a leave-in or styler can help hold moisture and cut frizz.',
        );
      }
      final dryish =
          c.drynessAfter ||
          c.drynessBefore ||
          p.concerns.contains(HairConcern.dryness);
      if (dryish &&
          prePoo == 0 &&
          (c.curlyOrCoily || p.concerns.contains(HairConcern.breakage))) {
        b.add(
          'You haven\'t logged a pre-poo; try one before washing to reduce dryness.',
        );
      } else if (dryish && prePoo * 2 >= n && c.drynessAfter) {
        b.add(
          'You pre-poo often but hair still felt dry after washing; try a '
          'different pre-poo type or add a moisture deep treatment.',
        );
      }
    }

    if (c.trend > 0) {
      b.add(
        'Hair has felt better after your recent washes than earlier ones — your changes are working.',
      );
    }
    return b.top();
  }

  // ---- schedule note ------------------------------------------------------

  static String _scheduleNote(_Ctx c, int interval) {
    final p = c.profile;
    final pattern = p.curlPattern.isEmpty
        ? 'your'
        : p.curlPattern.toUpperCase();
    final limits = switch (c.fam) {
      1 || 2 =>
        '${c.fam == 1 ? 'Straight' : 'Wavy'} hair ($pattern) gets oily '
            'faster when worn out, so we keep the schedule under a week: '
            'never more than 6 days between washes.',
      3 =>
        'Curly hair ($pattern) tends to be drier, so we space washes at '
            'least 3 days apart (no more than twice a week).',
      _ =>
        'Coily hair ($pattern) is the driest and most fragile, so we space '
            'washes at least 3 days apart (no more than twice a week); '
            'every 3–7 days is gentler.',
    };

    final gaps = <int>[];
    final days = <DateTime>[];
    for (final l in c.allLogs) {
      final d = DateTime.utc(l.date.year, l.date.month, l.date.day);
      if (days.isEmpty || days.last != d) days.add(d);
    }
    final used = days.take(5).toList();
    for (var i = 0; i + 1 < used.length; i++) {
      gaps.add(used[i].difference(used[i + 1]).inDays);
    }
    if (gaps.isEmpty) return limits;

    final avg = gaps.reduce((a, b) => a + b) / gaps.length;
    final rounded = avg.round();
    final actual =
        'You\'ve been washing about every '
        '${rounded <= 1 ? 'day' : '$rounded days'}';
    final String verdict;
    if (c.fam >= 3 && avg < 3) {
      verdict =
          'That\'s more often than the twice-a-week limit; for $pattern hair '
          'every 3–7 days is gentler.';
    } else if (c.fam <= 2 && avg > 6) {
      verdict =
          'That\'s a week or more between washes; looser hair does better '
          'with a wash at least every 6 days.';
    } else if ((avg - interval).abs() <= 1) {
      verdict =
          'That\'s right in line with the recommended every $interval days.';
    } else if (avg < interval) {
      verdict =
          'That\'s more often than the recommended every $interval days; '
          'it\'s fine if your scalp feels oily, otherwise try stretching it.';
    } else {
      verdict =
          'That\'s longer than the recommended every $interval days; wash '
          'sooner if your scalp gets itchy, oily or buildup shows.';
    }
    return '$limits $actual (${gaps.length + 1} recent washes). $verdict';
  }

  static const _cap = 8;
}

/// De-duplicating, ordered, capped list builder.
class _Bag {
  final items = <String>[];
  void add(String v) {
    if (!items.contains(v)) items.add(v);
  }

  List<String> top() => items.take(WashInsightsEngine._cap).toList();
}

class _Ctx {
  _Ctx({
    required this.profile,
    required this.recent,
    required this.allLogs,
    required this.dryBefore,
    required this.oilyBefore,
    required this.dryAfter,
    required this.oilyAfter,
    required this.normalBefore,
    required this.normalAfter,
    required this.drynessBefore,
    required this.oilinessBefore,
    required this.drynessAfter,
    required this.oilinessAfter,
  }) {
    fam =
        int.tryParse(
          profile.curlPattern.isEmpty ? '' : profile.curlPattern[0],
        ) ??
        2;
    sub = profile.curlPattern.length > 1
        ? profile.curlPattern[1].toUpperCase()
        : '';
    styles = {...profile.styling, for (final l in recent) ...l.styling};
    protective = styles.any(
      (s) =>
          s == HairStyling.braidsTwists ||
          s == HairStyling.wigs ||
          s == HairStyling.updos,
    );

    final heatLogs = allLogs.where(
      (l) => l.styling.contains(HairStyling.heatStyled),
    );
    heatDryAfter =
        heatLogs.where((l) => l.feelAfter == HairFeel.dry).length >= 2;
    protectiveOilyBefore =
        allLogs
            .where(
              (l) =>
                  l.feelBefore == HairFeel.oily &&
                  (l.styling.contains(HairStyling.braidsTwists) ||
                      l.styling.contains(HairStyling.wigs)),
            )
            .length >=
        2;

    // Compare how often "dry after" shows up in newer vs older washes.
    final withAfter = allLogs.where((l) => l.feelAfter != null).toList();
    if (withAfter.length >= 4) {
      final half = withAfter.length ~/ 2;
      double dryShare(Iterable<WashLog> v) =>
          v.where((l) => l.feelAfter == HairFeel.dry).length / v.length;
      final newer = dryShare(withAfter.take(half));
      final older = dryShare(withAfter.skip(half));
      if (newer - older >= 0.4) {
        trend = -1;
      } else if (older - newer >= 0.4) {
        trend = 1;
      }
    }
  }

  final HairProfile profile;
  final List<WashLog> recent;
  final List<WashLog> allLogs; // newest first
  final bool dryBefore,
      oilyBefore,
      dryAfter,
      oilyAfter,
      normalBefore,
      normalAfter;
  final bool drynessBefore, oilinessBefore, drynessAfter, oilinessAfter;
  late final int fam;
  late final String sub;
  late final Set<HairStyling> styles;
  late final bool protective;
  late bool heatDryAfter;
  late bool protectiveOilyBefore;

  /// -1 hair getting drier after washes, 1 getting better, 0 no trend.
  int trend = 0;

  bool get curlyOrCoily => fam >= 3;
}
