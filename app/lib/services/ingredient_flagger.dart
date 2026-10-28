import '../models/product.dart';

/// Pure rules for flagging ingredients (sulfates, silicones, drying alcohols).
abstract final class IngredientFlagger {
  static final _sulfate = RegExp(r'(lauryl|laureth|myreth|coco)[- ]sulfate');

  // Fatty alcohols (cetyl, stearyl, cetearyl, behenyl) are emollients, not drying.
  static const _dryingAlcohols = {
    'alcohol denat',
    'alcohol denat.',
    'denatured alcohol',
    'sd alcohol',
    'sd alcohol 40',
    'ethanol',
    'isopropyl alcohol',
    'propanol',
  };

  static IngredientFlag? flagFor(String ingredient) {
    final n = ingredient.trim().toLowerCase();
    if (_sulfate.hasMatch(n)) return IngredientFlag.sulfate;
    if (n.endsWith('cone') ||
        n.endsWith('conol') ||
        n.endsWith('siloxane') ||
        n.endsWith('cone crosspolymer')) {
      return IngredientFlag.silicone;
    }
    if (_dryingAlcohols.contains(n)) return IngredientFlag.dryingAlcohol;
    return null;
  }

  /// Flags found in [ingredients], mapped to the offending ingredient names.
  static Map<IngredientFlag, List<String>> flag(List<String> ingredients) {
    final result = <IngredientFlag, List<String>>{};
    for (final i in ingredients) {
      final f = flagFor(i);
      if (f != null) result.putIfAbsent(f, () => []).add(i);
    }
    return result;
  }
}
