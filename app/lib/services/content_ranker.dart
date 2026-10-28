import '../models/content_item.dart';
import '../models/hair_profile.dart';

/// Rule-based feed personalization (v1: no ML).
abstract final class ContentRanker {
  static bool _matchesCurl(ContentItem item, String curl) =>
      item.curlPatterns.isEmpty ||
      item.curlPatterns.contains(curl) ||
      (curl.isNotEmpty && item.curlPatterns.contains(curl[0]));

  static int score(ContentItem item, HairProfile profile) {
    var s = 0;
    if (item.curlPatterns.isNotEmpty &&
        _matchesCurl(item, profile.curlPattern)) {
      s += item.curlPatterns.contains(profile.curlPattern) ? 3 : 2;
    }
    s += 2 * item.concerns.intersection(profile.concerns).length;
    return s;
  }

  /// Drops items for other curl patterns, then sorts by relevance
  /// (stable for ties).
  static List<ContentItem> rank(List<ContentItem> items, HairProfile profile) {
    final eligible =
        items.where((i) => _matchesCurl(i, profile.curlPattern)).toList();
    final order = {for (var k = 0; k < eligible.length; k++) eligible[k]: k};
    eligible.sort((a, b) {
      final c = score(b, profile).compareTo(score(a, profile));
      return c != 0 ? c : order[a]!.compareTo(order[b]!);
    });
    return eligible;
  }
}
