enum IngredientFlag { sulfate, silicone, dryingAlcohol }

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.ingredients,
    required this.sourceUrl,
    this.curlPatterns = const [],
  }) : assert(sourceUrl != '');

  final String id;
  final String name;
  final String brand;

  /// INCI list in label order.
  final List<String> ingredients;

  /// Citation for the ingredient list (R2).
  final String sourceUrl;

  /// Curl families this product is explicitly intended for.
  final List<String> curlPatterns;
}
