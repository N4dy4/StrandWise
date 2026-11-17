/// A linked how-to video for a hairstyle. Cite and link out only (R2).
class HairstyleTutorial {
  const HairstyleTutorial({
    required this.styleName,
    required this.title,
    required this.sourceName,
    required this.sourceUrl,
    this.thumbnailUrl = '',
    this.platform = 'youtube',
    this.curlPatterns = const [],
  });

  final String styleName;
  final String title;
  final String sourceName;
  final String sourceUrl;
  final String thumbnailUrl;
  final String platform;

  /// Curl families like '3', '4'; empty means any.
  final List<String> curlPatterns;

  factory HairstyleTutorial.fromJson(Map<String, dynamic> j) =>
      HairstyleTutorial(
        styleName: j['style_name'] as String? ?? '',
        title: unescapeHtml(j['title'] as String? ?? ''),
        sourceName: unescapeHtml(j['source_name'] as String? ?? ''),
        sourceUrl: j['source_url'] as String? ?? '',
        thumbnailUrl: j['thumbnail_url'] as String? ?? '',
        platform: j['platform'] as String? ?? 'youtube',
        curlPatterns: [
          for (final p in (j['curl_patterns'] as List? ?? const []))
            if (p != null) p.toString(),
        ],
      );
}

const _namedEntities = {
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
};

String unescapeHtml(String s) =>
    s.replaceAllMapped(RegExp(r'&(#x[0-9a-fA-F]+|#\d+|[a-zA-Z]+);'), (m) {
      final e = m[1]!;
      if (e.startsWith('#x')) {
        final c = int.tryParse(e.substring(2), radix: 16);
        return c == null ? m[0]! : String.fromCharCode(c);
      }
      if (e.startsWith('#')) {
        final c = int.tryParse(e.substring(1));
        return c == null ? m[0]! : String.fromCharCode(c);
      }
      return _namedEntities[e] ?? m[0]!;
    });

/// Keeps tutorials for the user's curl family (e.g. '4' from '4C') first,
/// then any-family ones; hides tutorials for other families.
List<HairstyleTutorial> rankTutorials(
  List<HairstyleTutorial> all,
  String curlPattern, {
  int limit = 6,
}) {
  final family = curlPattern.isEmpty ? '' : curlPattern[0];
  final exact = [
    for (final t in all)
      if (t.curlPatterns.contains(family)) t,
  ];
  final any = [
    for (final t in all)
      if (t.curlPatterns.isEmpty) t,
  ];
  return [...exact, ...any].take(limit).toList();
}

String curlFamilyLabel(String curlPattern) =>
    switch (curlPattern.isEmpty ? '' : curlPattern[0]) {
      '1' => 'straight',
      '2' => 'wavy',
      '3' => 'curly',
      '4' => 'coily',
      _ => '',
    };

Uri youtubeSearchUri(String style, String curlPattern) {
  final label = curlFamilyLabel(curlPattern);
  final q = Uri.encodeQueryComponent(
    '$style tutorial${label.isEmpty ? '' : ' $label'} hair',
  );
  return Uri.parse('https://www.youtube.com/results?search_query=$q');
}
