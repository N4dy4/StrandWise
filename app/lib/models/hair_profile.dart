import 'dart:convert';

enum HairConcern { frizz, breakage, dandruff, dryness, hairLoss }

enum Porosity { low, medium, high }

enum Density { thin, medium, thick }

enum StrandSize { fine, medium, coarse }

enum ScalpType { dry, balanced, oily }

enum WashFrequency {
  daily(1, 'Every day'),
  fewDays(3, 'Every 2–4 days'),
  weekly(7, 'About once a week'),
  biweekly(14, 'Every 2 weeks or less');

  const WashFrequency(this.days, this.label);
  final int days;
  final String label;
}

enum HairStyling {
  out('Wear it out'),
  braidsTwists('Braids / twists'),
  wigs('Wigs / weaves'),
  updos('Buns / updos'),
  heatStyled('Heat styled');

  const HairStyling(this.label);
  final String label;
}

T? _byName<T extends Enum>(List<T> values, Object? name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}

/// Profile built by the onboarding quiz; drives routines and the feed.
class HairProfile {
  const HairProfile({
    required this.curlPattern,
    this.name = '',
    this.porosity = Porosity.medium,
    this.density = Density.medium,
    this.strandSize = StrandSize.medium,
    this.scalp = ScalpType.balanced,
    this.concerns = const {},
    this.colorTreated = false,
    this.washFrequency,
    this.styling = const {},
  });

  /// e.g. "3B" (1A–4C).
  final String curlPattern;

  /// First name used for greetings; may be empty.
  final String name;

  /// Not asked in the quiz; stays at the default unless set elsewhere.
  final Porosity porosity;
  final Density density;
  final StrandSize strandSize;
  final ScalpType scalp;

  /// The quiz asks for the single biggest concern, so this holds at most one.
  final Set<HairConcern> concerns;
  final bool colorTreated;

  /// How often the user says they wash; null falls back to the rule-based default.
  final WashFrequency? washFrequency;
  final Set<HairStyling> styling;

  Map<String, dynamic> toJson() => {
    'curlPattern': curlPattern,
    'name': name,
    'porosity': porosity.name,
    'density': density.name,
    'strandSize': strandSize.name,
    'scalp': scalp.name,
    'concerns': concerns.map((c) => c.name).toList(),
    'colorTreated': colorTreated,
    'washFrequency': washFrequency?.name,
    'styling': styling.map((s) => s.name).toList(),
  };

  /// Tolerant of profiles saved before newer fields existed.
  factory HairProfile.fromJson(Map<String, dynamic> j) => HairProfile(
    curlPattern: j['curlPattern'] as String,
    name: j['name'] as String? ?? '',
    porosity: _byName(Porosity.values, j['porosity']) ?? Porosity.medium,
    density: _byName(Density.values, j['density']) ?? Density.medium,
    strandSize:
        _byName(StrandSize.values, j['strandSize']) ?? StrandSize.medium,
    scalp: _byName(ScalpType.values, j['scalp']) ?? ScalpType.balanced,
    concerns: {
      for (final c in (j['concerns'] as List? ?? const []))
        ?_byName(HairConcern.values, c),
    },
    colorTreated: j['colorTreated'] as bool? ?? false,
    washFrequency: _byName(WashFrequency.values, j['washFrequency']),
    styling: {
      for (final s in (j['styling'] as List? ?? const []))
        ?_byName(HairStyling.values, s),
    },
  );

  String encode() => jsonEncode(toJson());
  static HairProfile decode(String s) =>
      HairProfile.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
