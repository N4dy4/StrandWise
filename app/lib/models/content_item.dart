import 'hair_profile.dart';

enum ContentType { video, article }

/// A web-sourced item. [sourceUrl] is mandatory so every item carries a
/// permanent citation (R2); we link out and never re-host.
class ContentItem {
  const ContentItem({
    required this.id,
    required this.type,
    required this.title,
    required this.sourceName,
    required this.sourceUrl,
    this.curlPatterns = const {},
    this.concerns = const {},
  }) : assert(sourceUrl != '');

  final String id;
  final ContentType type;
  final String title;
  final String sourceName;
  final String sourceUrl;

  /// Curl patterns (e.g. "3B") or families (e.g. "3") this applies to.
  /// Empty means all hair types.
  final Set<String> curlPatterns;
  final Set<HairConcern> concerns;

  bool get isMedicalSensitive =>
      concerns.contains(HairConcern.hairLoss) ||
      concerns.contains(HairConcern.dandruff);

  factory ContentItem.fromJson(Map<String, dynamic> json) => ContentItem(
        id: json['id'] as String,
        type: ContentType.values.byName(json['type'] as String),
        title: json['title'] as String,
        sourceName: json['source_name'] as String,
        sourceUrl: json['source_url'] as String,
        curlPatterns: ((json['curl_patterns'] as List?) ?? const [])
            .cast<String>()
            .toSet(),
        concerns: ((json['concerns'] as List?) ?? const [])
            .map((c) => HairConcern.values.byName(c as String))
            .toSet(),
      );
}
