import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/hair_profile.dart';
import 'hairstyle_recommender.dart';

class AiProduct {
  const AiProduct({
    required this.name,
    required this.brand,
    required this.sourceUrl,
  });

  final String name;
  final String brand;

  /// Citation link (R2).
  final String sourceUrl;
}

class AiAnswer {
  const AiAnswer({required this.text, this.products = const []});

  final String text;
  final List<AiProduct> products;
}

/// Small-LLM helper, served by the `ask-hair-ai` Edge Function so the model
/// key never ships in the app. Methods throw when AI is unavailable.
abstract class AiAssistant {
  Future<AiAnswer> ask(String question, HairProfile profile);

  Future<List<HairstyleIdea>> hairstyles(
    HairProfile profile,
    Set<StyleGoal> goals,
  );

  bool get isAvailable;

  factory AiAssistant.create() => SupabaseConfig.isConfigured
      ? SupabaseAiAssistant()
      : const UnavailableAiAssistant();
}

class UnavailableAiAssistant implements AiAssistant {
  const UnavailableAiAssistant();

  @override
  bool get isAvailable => false;

  @override
  Future<AiAnswer> ask(String question, HairProfile profile) =>
      Future.error(StateError('AI needs a Supabase connection.'));

  @override
  Future<List<HairstyleIdea>> hairstyles(
    HairProfile profile,
    Set<StyleGoal> goals,
  ) => Future.error(StateError('AI needs a Supabase connection.'));
}

class SupabaseAiAssistant implements AiAssistant {
  @override
  bool get isAvailable => true;

  Future<Map<String, dynamic>> _call(Map<String, dynamic> body) async {
    final res = await Supabase.instance.client.functions.invoke(
      'ask-hair-ai',
      body: body,
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  @override
  Future<AiAnswer> ask(String question, HairProfile profile) async {
    final data = await _call({
      'mode': 'ask',
      'question': question,
      'profile': profile.toJson(),
    });
    return AiAnswer(
      text: data['answer'] as String? ?? '',
      products: [
        for (final p in (data['products'] as List? ?? const []))
          AiProduct(
            name: p['name'] as String,
            brand: p['brand'] as String,
            sourceUrl: p['source_url'] as String,
          ),
      ],
    );
  }

  @override
  Future<List<HairstyleIdea>> hairstyles(
    HairProfile profile,
    Set<StyleGoal> goals,
  ) async {
    final data = await _call({
      'mode': 'styles',
      'profile': profile.toJson(),
      'preferences': goals.map((g) => g.label).join(', '),
    });
    return [
      for (final s in (data['styles'] as List? ?? const []))
        HairstyleIdea(
          name: s['name'] as String,
          why: s['why'] as String? ?? '',
          care: s['care'] as String? ?? '',
        ),
    ];
  }
}
