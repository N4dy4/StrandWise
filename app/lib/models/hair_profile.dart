enum HairConcern { frizz, breakage, dandruff, dryness, hairLoss }

/// Minimal profile used to personalize content. Phase 1's onboarding quiz
/// will populate this.
class HairProfile {
  const HairProfile({required this.curlPattern, this.concerns = const {}});

  /// e.g. "3B" (1A–4C).
  final String curlPattern;
  final Set<HairConcern> concerns;
}
