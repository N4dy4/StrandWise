enum IngredientFlag { sulfate, silicone, dryingAlcohol }

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.ingredients,
    required this.sourceUrl,
    this.description = '',
    this.curlPatterns = const [],
  }) : assert(sourceUrl != '');

  final String id;
  final String name;
  final String brand;

  /// INCI list in label order.
  final List<String> ingredients;

  /// Citation for the ingredient list (R2).
  final String sourceUrl;

  /// Short blurb from the brand's product page; empty when unavailable.
  final String description;

  /// Curl families this product is explicitly intended for.
  final List<String> curlPatterns;
}
