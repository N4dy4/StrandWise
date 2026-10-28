import 'dart:convert';

enum HairConcern { frizz, breakage, dandruff, dryness, hairLoss }

enum Porosity { low, medium, high }

enum Density { thin, medium, thick }

enum ScalpType { dry, balanced, oily }

/// Profile built by the onboarding quiz; drives routines and the feed.
class HairProfile {
  const HairProfile({
    required this.curlPattern,
    this.porosity = Porosity.medium,
    this.density = Density.medium,
    this.scalp = ScalpType.balanced,
    this.concerns = const {},
  });

  /// e.g. "3B" (1A–4C).
  final String curlPattern;
  final Porosity porosity;
  final Density density;
  final ScalpType scalp;
  final Set<HairConcern> concerns;

  Map<String, dynamic> toJson() => {
        'curlPattern': curlPattern,
        'porosity': porosity.name,
        'density': density.name,
        'scalp': scalp.name,
        'concerns': concerns.map((c) => c.name).toList(),
      };

  factory HairProfile.fromJson(Map<String, dynamic> j) => HairProfile(
        curlPattern: j['curlPattern'] as String,
        porosity: Porosity.values.byName(j['porosity'] as String),
        density: Density.values.byName(j['density'] as String),
        scalp: ScalpType.values.byName(j['scalp'] as String),
        concerns: (j['concerns'] as List)
            .map((c) => HairConcern.values.byName(c as String))
            .toSet(),
      );

  String encode() => jsonEncode(toJson());
  static HairProfile decode(String s) =>
      HairProfile.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
