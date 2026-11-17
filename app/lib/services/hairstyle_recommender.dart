import '../models/hair_profile.dart';

enum StyleGoal { lowMaintenance, protective, definition, volume, heatFree }

extension StyleGoalLabel on StyleGoal {
  String get label => switch (this) {
    StyleGoal.lowMaintenance => 'Low maintenance',
    StyleGoal.protective => 'Protective',
    StyleGoal.definition => 'Curl definition',
    StyleGoal.volume => 'Volume',
    StyleGoal.heatFree => 'Heat-free',
  };
}

class HairstyleIdea {
  const HairstyleIdea({
    required this.name,
    required this.why,
    required this.care,
  });

  final String name;
  final String why;
  final String care;
}

class _Style {
  const _Style(
    this.name,
    this.families,
    this.goals,
    this.care, {
    this.tension = false,
    this.heat = false,
  });

  final String name;
  final Set<String> families;
  final Set<StyleGoal> goals;
  final String care;

  /// Pulls on the hairline/strands; avoided with breakage or hair-loss concerns.
  final bool tension;

  /// Needs direct heat; scored lower for color-treated hair.
  final bool heat;
}

/// Rule-based hairstyle suggestions (v1: no ML); also the offline fallback
/// for the AI recommendations.
class HairstyleRecommender {
  static const _all = [
    _Style(
      'Wash-and-go',
      {'2', '3', '4'},
      {StyleGoal.definition, StyleGoal.heatFree, StyleGoal.volume},
      'Style on soaking-wet hair with a leave-in and gel; refresh with water.',
    ),
    _Style(
      'Twist-out',
      {'3', '4'},
      {StyleGoal.definition, StyleGoal.heatFree, StyleGoal.volume},
      'Twist on damp, moisturized hair and let it dry fully before unraveling.',
    ),
    _Style(
      'Braid-out',
      {'2', '3', '4'},
      {StyleGoal.definition, StyleGoal.heatFree},
      'Braid on damp hair with a cream; re-braid loosely at night to extend it.',
    ),
    _Style(
      'Pineapple bun / high puff',
      {'3', '4'},
      {StyleGoal.lowMaintenance, StyleGoal.heatFree, StyleGoal.volume},
      'Use a soft scrunchie and loosen it daily to avoid tension.',
    ),
    _Style(
      'Loose protective braids',
      {'3', '4'},
      {StyleGoal.protective, StyleGoal.lowMaintenance, StyleGoal.heatFree},
      'Keep them loose, moisturize the lengths weekly and take them out within 6–8 weeks.',
      tension: true,
    ),
    _Style(
      'Flat twists',
      {'3', '4'},
      {StyleGoal.protective, StyleGoal.lowMaintenance, StyleGoal.heatFree},
      'Seal ends with oil or butter and wrap hair at night.',
    ),
    _Style(
      'Silk press',
      {'2', '3', '4'},
      {StyleGoal.volume},
      'Use a heat protectant and keep heat low; limit to occasional wear.',
      heat: true,
    ),
    _Style(
      'Layered cut with diffused finish',
      {'1', '2', '3'},
      {StyleGoal.volume, StyleGoal.definition, StyleGoal.lowMaintenance},
      'Diffuse on low heat or air-dry; trim every 8–12 weeks.',
    ),
    _Style(
      'Air-dried waves',
      {'1', '2'},
      {StyleGoal.lowMaintenance, StyleGoal.heatFree, StyleGoal.definition},
      'Scrunch in a light mousse or cream and avoid touching until dry.',
    ),
    _Style(
      'Low bun',
      {'1', '2', '3', '4'},
      {StyleGoal.protective, StyleGoal.lowMaintenance, StyleGoal.heatFree},
      'Tuck the ends in and vary the position to protect your edges.',
    ),
    _Style(
      'Bantu knots',
      {'3', '4'},
      {StyleGoal.protective, StyleGoal.definition, StyleGoal.heatFree},
      'Do not twist tightly; undo them on dry hair for defined curls.',
      tension: true,
    ),
    _Style(
      'Knotless braids',
      {'2', '3', '4'},
      {StyleGoal.protective, StyleGoal.lowMaintenance, StyleGoal.heatFree},
      'Keep the parts light, moisturize the scalp weekly and take them down within 6–8 weeks.',
      tension: true,
    ),
    _Style(
      'Box braids',
      {'3', '4'},
      {StyleGoal.protective, StyleGoal.lowMaintenance, StyleGoal.heatFree},
      'Avoid small, tight parts, cleanse the scalp gently and remove within 6–8 weeks.',
      tension: true,
    ),
    _Style(
      'Cornrows',
      {'3', '4'},
      {StyleGoal.protective, StyleGoal.lowMaintenance, StyleGoal.heatFree},
      'Braid snugly but never tight, moisturize the scalp and keep them for 2–4 weeks.',
      tension: true,
    ),
    _Style(
      'Passion twists',
      {'3', '4'},
      {StyleGoal.protective, StyleGoal.lowMaintenance, StyleGoal.heatFree},
      'Moisturize your natural hair at the roots weekly and wrap them at night.',
      tension: true,
    ),
    _Style(
      'Mini twists',
      {'3', '4'},
      {StyleGoal.protective, StyleGoal.lowMaintenance, StyleGoal.heatFree},
      'Twist on damp, moisturized hair, keep them loose at the root and refresh with a light oil; wear for 3–6 weeks.',
    ),
    _Style(
      'Mini braids',
      {'2', '3', '4'},
      {StyleGoal.protective, StyleGoal.lowMaintenance, StyleGoal.heatFree},
      'Keep them loose, moisturize the scalp and lengths weekly and take them down within 6–8 weeks.',
      tension: true,
    ),
    _Style(
      'Two-strand twists',
      {'3', '4'},
      {StyleGoal.protective, StyleGoal.definition, StyleGoal.heatFree},
      'Twist on moisturized hair, seal the ends and re-twist as needed.',
    ),
    _Style(
      'Finger coils',
      {'3', '4'},
      {StyleGoal.definition, StyleGoal.heatFree},
      'Coil on wet hair with a gel or custard and avoid touching until fully dry.',
    ),
    _Style(
      'Curly bob',
      {'2', '3'},
      {StyleGoal.volume, StyleGoal.definition, StyleGoal.lowMaintenance},
      'Cut when dry for shape, refresh with a spritz of water and trim every 8–10 weeks.',
    ),
    _Style(
      'Shag cut',
      {'1', '2', '3'},
      {StyleGoal.volume, StyleGoal.lowMaintenance},
      'Air-dry or diffuse with a light cream and trim the layers every 8–12 weeks.',
    ),
    _Style(
      'Sleek low ponytail',
      {'1', '2', '3', '4'},
      {StyleGoal.lowMaintenance, StyleGoal.heatFree},
      'Use a gentle, snag-free elastic and change the ponytail position often.',
      tension: true,
    ),
    _Style(
      'Space buns',
      {'2', '3', '4'},
      {StyleGoal.volume, StyleGoal.lowMaintenance, StyleGoal.heatFree},
      'Keep the buns loose with soft scrunchies and avoid pulling at the hairline.',
    ),
    _Style(
      'Half-up half-down',
      {'1', '2', '3', '4'},
      {StyleGoal.lowMaintenance, StyleGoal.volume, StyleGoal.heatFree},
      'Use a clip or loose tie and alternate the placement to spread out the stress.',
    ),
    _Style(
      'Roller set',
      {'1', '2', '3', '4'},
      {StyleGoal.volume, StyleGoal.definition},
      'Set on damp hair, dry fully under a hooded dryer on low and wrap at night.',
    ),
    _Style(
      'Flexi rod set',
      {'2', '3', '4'},
      {StyleGoal.definition, StyleGoal.heatFree},
      'Wrap damp hair with a setting lotion and let it air-dry fully before removing.',
    ),
    _Style(
      'Perm rod set',
      {'3', '4'},
      {StyleGoal.definition, StyleGoal.heatFree, StyleGoal.volume},
      'Wrap on damp, moisturized hair and let it dry completely before unrolling.',
    ),
    _Style(
      'Straw set',
      {'2', '3'},
      {StyleGoal.definition, StyleGoal.heatFree},
      'Wrap damp hair around straws with a light mousse and let it air-dry.',
    ),
    _Style(
      'Faux locs',
      {'3', '4'},
      {StyleGoal.protective, StyleGoal.lowMaintenance, StyleGoal.heatFree},
      'Choose lightweight locs, cleanse the scalp every 2 weeks and remove within 6–8 weeks.',
      tension: true,
    ),
    _Style(
      'Crochet braids',
      {'3', '4'},
      {StyleGoal.protective, StyleGoal.lowMaintenance, StyleGoal.heatFree},
      'Keep the braided base loose, moisturize the scalp and take down within 4–6 weeks.',
      tension: true,
    ),
    _Style(
      'Protective wig install',
      {'1', '2', '3', '4'},
      {StyleGoal.protective, StyleGoal.lowMaintenance, StyleGoal.heatFree},
      'Keep the install light, give your scalp breaks and moisturize the hair underneath weekly.',
      tension: true,
    ),
    _Style(
      'Rope twists',
      {'3', '4'},
      {StyleGoal.protective, StyleGoal.lowMaintenance, StyleGoal.heatFree},
      'Moisturize the roots weekly, wrap at night and remove within 6–8 weeks.',
      tension: true,
    ),
    _Style(
      'Halo braid',
      {'1', '2', '3', '4'},
      {StyleGoal.protective, StyleGoal.lowMaintenance, StyleGoal.heatFree},
      'Braid loosely, tuck the ends and avoid wearing it tight for several days in a row.',
      tension: true,
    ),
    _Style(
      'Dutch braids',
      {'1', '2', '3', '4'},
      {StyleGoal.protective, StyleGoal.lowMaintenance, StyleGoal.heatFree},
      'Braid gently without pulling at the edges and re-moisturize the lengths every few days.',
      tension: true,
    ),
    _Style(
      'Slick back bun',
      {'1', '2', '3', '4'},
      {StyleGoal.lowMaintenance, StyleGoal.heatFree},
      'Use a soft brush and a light gel, and take it down at night to rest your edges.',
      tension: true,
    ),
    _Style(
      'Curtain bangs with layers',
      {'1', '2'},
      {StyleGoal.volume, StyleGoal.lowMaintenance},
      'Trim the bangs every 4–6 weeks and the layers every 8–12 weeks.',
    ),
    _Style(
      'Silk wrap',
      {'1', '2', '3', '4'},
      {StyleGoal.heatFree, StyleGoal.lowMaintenance, StyleGoal.volume},
      'Wrap damp hair around your head with a silk scarf overnight and refresh it in the morning.',
    ),
  ];

  /// Names of every style in the catalog (keys for how-to videos).
  static List<String> get allNames => [for (final s in _all) s.name];

  static List<HairstyleIdea> recommend(
    HairProfile profile,
    Set<StyleGoal> goals, {
    int limit = 6,
  }) {
    final family = profile.curlPattern.isEmpty ? '3' : profile.curlPattern[0];
    final fragile =
        profile.concerns.contains(HairConcern.breakage) ||
        profile.concerns.contains(HairConcern.hairLoss);
    final scored = <(int, _Style)>[];
    for (final s in _all) {
      if (!s.families.contains(family)) continue;
      if (fragile && s.tension) continue;
      var score = s.goals.intersection(goals).length * 3;
      if (profile.concerns.contains(HairConcern.dryness) &&
          s.goals.contains(StyleGoal.protective)) {
        score += 1;
      }
      if (profile.concerns.contains(HairConcern.frizz) &&
          s.goals.contains(StyleGoal.definition)) {
        score += 1;
      }
      if (profile.density == Density.thin &&
          s.goals.contains(StyleGoal.volume)) {
        score += 1;
      }
      if ((profile.styling.contains(HairStyling.braidsTwists) ||
              profile.styling.contains(HairStyling.wigs)) &&
          s.goals.contains(StyleGoal.protective)) {
        score += 1;
      }
      if (profile.colorTreated && s.goals.contains(StyleGoal.heatFree)) {
        score += 1;
      }
      if (profile.colorTreated && s.heat) score -= 3;
      if (profile.styling.contains(HairStyling.wigs) &&
          s.name == 'Protective wig install') {
        score += 2;
      }
      if (profile.styling.contains(HairStyling.braidsTwists) &&
          s.name.contains('braids')) {
        score += 1;
      }
      if (profile.styling.contains(HairStyling.updos) &&
          s.goals.contains(StyleGoal.lowMaintenance) &&
          s.name.contains('bun')) {
        score += 1;
      }
      if (profile.styling.contains(HairStyling.heatStyled) &&
          s.goals.contains(StyleGoal.heatFree)) {
        score += 1;
      }
      if (profile.strandSize == StrandSize.fine &&
          s.goals.contains(StyleGoal.volume)) {
        score += 1;
      }
      final washDays = profile.washFrequency?.days ?? 0;
      if (washDays >= 7 && s.goals.contains(StyleGoal.protective)) score += 1;
      scored.add((score, s));
    }
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    return [
      for (final (_, s) in scored.take(limit))
        HairstyleIdea(name: s.name, why: _why(s, profile, goals), care: s.care),
    ];
  }

  static String _why(_Style s, HairProfile p, Set<StyleGoal> goals) {
    final matched = s.goals.intersection(goals);
    final parts = <String>[
      'Suits ${p.curlPattern} hair',
      if (matched.isNotEmpty)
        'fits your ${matched.map((g) => g.label.toLowerCase()).join(' + ')} goal',
      if (p.concerns.contains(HairConcern.dryness) &&
          s.goals.contains(StyleGoal.protective))
        'helps lock in moisture',
      if (p.concerns.contains(HairConcern.frizz) &&
          s.goals.contains(StyleGoal.definition))
        'helps control frizz',
      if (p.styling.contains(HairStyling.heatStyled) &&
          s.goals.contains(StyleGoal.heatFree))
        'a heat-free alternative to your usual styling',
    ];
    return '${parts.join(', ')}.';
  }
}
