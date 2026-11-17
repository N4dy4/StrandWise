/// Plain-language explainer for one ingredient, with a cited source (R2).
class IngredientInfo {
  const IngredientInfo({
    required this.whatItIs,
    required this.whyUsed,
    required this.hairEffects,
    required this.sourceUrl,
  });

  final String whatItIs;
  final String whyUsed;
  final String hairEffects;
  final String sourceUrl;
}
