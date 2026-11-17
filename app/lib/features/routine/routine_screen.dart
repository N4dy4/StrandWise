import 'package:flutter/material.dart';

import '../../data/content_repository.dart';
import '../../models/content_item.dart';
import '../../models/hair_profile.dart';
import '../../services/ai_assistant.dart';
import '../../services/content_ranker.dart';
import '../../services/hairstyle_recommender.dart';
import '../../services/routine_engine.dart';
import '../../theme/app_theme.dart';
import '../content/content_hub_screen.dart' show openSource;

/// Home dashboard: AI-tuned routine overview plus highlights from the
/// Learn feed and Hairstyles pages.
class RoutineScreen extends StatefulWidget {
  const RoutineScreen({
    super.key,
    required this.profile,
    this.repository,
    this.assistant,
  });

  final HairProfile profile;
  final ContentRepository? repository;
  final AiAssistant? assistant;

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  late final AiAssistant _assistant = widget.assistant ?? AiAssistant.create();
  late final Future<AiAnswer?> _plan = _loadPlan();
  late final Future<List<ContentItem>> _feed = _loadFeed();

  HairProfile get profile => widget.profile;

  Future<AiAnswer?> _loadPlan() async {
    if (!_assistant.isAvailable) return null;
    final routine = RoutineEngine.washDay(profile);
    final steps = routine.steps.map((s) => s.title).join(', ');
    try {
      return await _assistant.ask(
        'Tune my "${routine.name}" (${routine.frequency}; steps: $steps) '
        'for my hair. In 3 short sentences say what to focus on this week '
        'and name up to 3 products that fit.',
        profile,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<ContentItem>> _loadFeed() async {
    try {
      final repo = widget.repository ?? ContentRepository.create();
      return ContentRanker.rank(await repo.contentItems(), profile);
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final routine = RoutineEngine.washDay(profile);
    final styles = HairstyleRecommender.recommend(profile, {}, limit: 3);
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
        children: [
          Text(
            profile.name.isEmpty
                ? 'Welcome back'
                : 'Welcome back, ${profile.name}',
            style: const TextStyle(color: AppColors.deepPink),
          ),
          const SizedBox(height: 4),
          Text(
            'Your ${profile.curlPattern} hair routine',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Card(
            color: AppColors.pink,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personalized by your hair profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    routine.name,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${routine.frequency} · ${profile.strandSize.name} strands'
                    '${profile.colorTreated ? ' · color-treated' : ''}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, 'AI-optimized for you'),
          FutureBuilder<AiAnswer?>(
            future: _plan,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Tuning your routine…'),
                      ],
                    ),
                  ),
                );
              }
              final answer = snap.data;
              if (answer == null) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'AI tips are unavailable right now. Showing your '
                      'rule-based routine below.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                );
              }
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(answer.text),
                      if (answer.products.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final p in answer.products)
                              ActionChip(
                                avatar: const Icon(Icons.link, size: 16),
                                label: Text('${p.brand} ${p.name}'),
                                onPressed: () => openSource(p.sourceUrl),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      const Text(
                        'AI-generated; not medical advice.',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              shape: const Border(),
              title: Text(
                'Full routine (${routine.steps.length} steps)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              children: [
                for (final step in routine.steps)
                  _RoutineStepCard(title: step.title, detail: step.detail),
              ],
            ),
          ),
          _sectionTitle(context, 'From your feed'),
          FutureBuilder<List<ContentItem>>(
            future: _feed,
            builder: (context, snap) {
              final items = (snap.data ?? const <ContentItem>[])
                  .take(3)
                  .toList();
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Picks for your hair will appear here.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                );
              }
              return Column(
                children: [
                  for (final item in items)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          item.type == ContentType.video
                              ? Icons.play_circle_outline
                              : Icons.article_outlined,
                          color: AppColors.deepPink,
                        ),
                        title: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          ContentRanker.reason(item, profile) ??
                              'Picked for your profile',
                        ),
                        onTap: () => openSource(item.sourceUrl),
                      ),
                    ),
                ],
              );
            },
          ),
          _sectionTitle(context, 'Style ideas'),
          for (final s in styles)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.deepPink,
                ),
                title: Text(
                  s.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(s.why),
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'General guidance, not medical advice. For hair loss or scalp '
              'conditions, see a doctor or dermatologist.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _sectionTitle(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.only(top: 8, bottom: 8),
  child: Text(text, style: Theme.of(context).textTheme.titleMedium),
);

class _RoutineStepCard extends StatelessWidget {
  const _RoutineStepCard({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.rose,
        child: Icon(
          Icons.water_drop_outlined,
          color: AppColors.muted,
          size: 18,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(detail),
    ),
  );
}
