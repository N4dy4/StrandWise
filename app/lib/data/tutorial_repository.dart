import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/tutorial.dart';

abstract class TutorialRepository {
  /// Tutorials for all [styleNames] in a single query, grouped by style name.
  Future<Map<String, List<HairstyleTutorial>>> forStyles(
    List<String> styleNames,
  );

  factory TutorialRepository.create() => SupabaseConfig.isConfigured
      ? SupabaseTutorialRepository()
      : LocalTutorialRepository();
}

class LocalTutorialRepository implements TutorialRepository {
  @override
  Future<Map<String, List<HairstyleTutorial>>> forStyles(
    List<String> styleNames,
  ) async => const {};
}

class SupabaseTutorialRepository implements TutorialRepository {
  @override
  Future<Map<String, List<HairstyleTutorial>>> forStyles(
    List<String> styleNames,
  ) async {
    if (styleNames.isEmpty) return const {};
    final rows = await Supabase.instance.client
        .from('hairstyle_tutorials')
        .select(
          'style_name, title, source_name, source_url, thumbnail_url, platform, curl_patterns',
        )
        .inFilter('style_name', styleNames);
    final out = <String, List<HairstyleTutorial>>{};
    for (final r in rows) {
      final t = HairstyleTutorial.fromJson(r);
      if (t.sourceUrl.isEmpty) continue;
      out.putIfAbsent(t.styleName, () => []).add(t);
    }
    return out;
  }
}
