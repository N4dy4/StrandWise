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
  });

  final String name;
  final Set<String> families;
  final Set<StyleGoal> goals;
  final String care;

  /// Pulls on the hairline/strands; avoided with breakage or hair-loss concerns.
  final bool tension;
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
  ];

  static List<HairstyleIdea> recommend(
    HairProfile profile,
    Set<StyleGoal> goals, {
    int limit = 4,
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
    ];
    return '${parts.join(', ')}.';
  }
}
