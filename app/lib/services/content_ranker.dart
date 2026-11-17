import '../models/content_item.dart';
import '../models/hair_profile.dart';

/// Rule-based feed personalization (v1: no ML).
abstract final class ContentRanker {
  static const _recentWindow = Duration(days: 180);

  static bool _matchesCurl(ContentItem item, String curl) =>
      item.curlPatterns.isEmpty ||
      item.curlPatterns.contains(curl) ||
      (curl.isNotEmpty && item.curlPatterns.contains(curl[0]));

  /// Title keyword rules for porosity, density and scalp.
  static List<(RegExp, String)> _traitRules(HairProfile p) => [
    if (p.porosity == Porosity.low)
      (RegExp(r'low[- ]porosity'), 'low porosity'),
    if (p.porosity == Porosity.high)
      (RegExp(r'high[- ]porosity'), 'high porosity'),
    if (p.density == Density.thin)
      (RegExp(r'\bthin\b|\bfine hair\b|low density'), 'thin hair'),
    if (p.density == Density.thick)
      (RegExp(r'\bthick\b|high density'), 'thick hair'),
    if (p.scalp == ScalpType.oily) (RegExp(r'oily scalp'), 'oily scalp'),
    if (p.scalp == ScalpType.dry) (RegExp(r'dry scalp'), 'dry scalp'),
  ];

  static List<String> _traitHits(ContentItem item, HairProfile p) {
    final title = item.title.toLowerCase();
    return [
      for (final (re, label) in _traitRules(p))
        if (re.hasMatch(title)) label,
    ];
  }

  static bool _isRecent(ContentItem item, DateTime now) {
    final at = item.publishedAt;
    return at != null && now.difference(at) <= _recentWindow;
  }

  static int score(ContentItem item, HairProfile profile, {DateTime? now}) {
    var s = 0;
    if (item.curlPatterns.isNotEmpty &&
        _matchesCurl(item, profile.curlPattern)) {
      s += item.curlPatterns.contains(profile.curlPattern) ? 3 : 2;
    }
    s += 2 * item.concerns.intersection(profile.concerns).length;
    s += 2 * _traitHits(item, profile).length;
    if (_isRecent(item, now ?? DateTime.now())) s += 1;
    return s;
  }

  /// Short "why this" line, e.g. "Matches 4C · frizz"; null if generic.
  static String? reason(ContentItem item, HairProfile profile) {
    final parts = <String>[
      if (item.curlPatterns.isNotEmpty &&
          _matchesCurl(item, profile.curlPattern))
        profile.curlPattern,
      for (final c in HairConcern.values)
        if (item.concerns.contains(c) && profile.concerns.contains(c)) c.name,
      ..._traitHits(item, profile),
    ];
    return parts.isEmpty ? null : 'Matches ${parts.join(' · ')}';
  }

  /// Drops items for other curl patterns, sorts by relevance, then
  /// diversifies so the same platform/type doesn't dominate the top.
  /// Deterministic: ties keep input order.
  static List<ContentItem> rank(
    List<ContentItem> items,
    HairProfile profile, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final remaining = [
      for (final i in items)
        if (_matchesCurl(i, profile.curlPattern)) i,
    ];
    final base = {
      for (var k = 0; k < remaining.length; k++)
        remaining[k]: score(remaining[k], profile, now: clock),
    };
    final order = {for (var k = 0; k < remaining.length; k++) remaining[k]: k};
    remaining.sort((a, b) {
      final c = base[b]!.compareTo(base[a]!);
      return c != 0 ? c : order[a]!.compareTo(order[b]!);
    });

    // Each recent same-platform pick (last 3) costs one point.
    final result = <ContentItem>[];
    while (remaining.isNotEmpty) {
      final recent = result.reversed.take(3).toList();
      var best = 0;
      var bestScore = -1 << 30;
      for (var k = 0; k < remaining.length; k++) {
        final c = remaining[k];
        final penalty = recent.where((r) => r.platform == c.platform).length;
        final adjusted = base[c]! - penalty;
        if (adjusted > bestScore) {
          bestScore = adjusted;
          best = k;
        }
      }
      result.add(remaining.removeAt(best));
    }
    return result;
  }
}
