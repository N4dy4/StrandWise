import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/tutorial_repository.dart';
import '../../models/hair_profile.dart';
import '../../models/tutorial.dart';
import '../../services/ai_assistant.dart';
import '../../services/hairstyle_recommender.dart';
import '../../theme/app_theme.dart';
import '../content/content_hub_screen.dart' show openSource;

const _disclaimer =
    'Hair care ideas only. Not medical advice; see a doctor for scalp or hair loss concerns.';

class HairstyleScreen extends StatefulWidget {
  const HairstyleScreen({
    super.key,
    required this.profile,
    this.assistant,
    this.tutorials,
  });

  final HairProfile profile;
  final AiAssistant? assistant;
  final TutorialRepository? tutorials;

  @override
  State<HairstyleScreen> createState() => _HairstyleScreenState();
}

class _HairstyleScreenState extends State<HairstyleScreen> {
  late final AiAssistant _assistant = widget.assistant ?? AiAssistant.create();
  late final TutorialRepository _tutorialRepo =
      widget.tutorials ?? TutorialRepository.create();
  final _tutorialCache = <String, List<HairstyleTutorial>>{};
  final _requested = <String>{};
  final _goals = <StyleGoal>{StyleGoal.lowMaintenance};
  List<HairstyleIdea>? _aiIdeas;
  var _loading = false;
  String? _error;

  Future<void> _askAi() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ideas = await _assistant.hairstyles(widget.profile, _goals);
      if (!mounted) return;
      setState(() => _aiIdeas = ideas);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'AI suggestions are unavailable right now.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // One batched query for styles not fetched yet; never blocks the list.
  void _loadTutorials(List<HairstyleIdea> ideas) {
    final missing = [
      for (final i in ideas)
        if (!_requested.contains(i.name)) i.name,
    ];
    if (missing.isEmpty) return;
    _requested.addAll(missing);
    unawaited(() async {
      Map<String, List<HairstyleTutorial>> found;
      try {
        found = await _tutorialRepo.forStyles(missing);
      } catch (_) {
        found = const {};
      }
      if (!mounted) return;
      setState(() {
        for (final n in missing) {
          _tutorialCache[n] = found[n] ?? const [];
        }
      });
    }());
  }

  void _toggle(StyleGoal goal, bool on) => setState(() {
    on ? _goals.add(goal) : _goals.remove(goal);
    _aiIdeas = null;
  });

  @override
  Widget build(BuildContext context) {
    final ideas =
        _aiIdeas ?? HairstyleRecommender.recommend(widget.profile, _goals);
    _loadTutorials(ideas);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      children: [
        Text(
          'Hairstyles for you',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Based on your ${widget.profile.curlPattern} hair and preferences',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in StyleGoal.values)
              FilterChip(
                label: Text(g.label),
                selected: _goals.contains(g),
                onSelected: (on) => _toggle(g, on),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (ideas.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('No matches yet. Try removing a preference.'),
            ),
          ),
        for (final idea in ideas)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    idea.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(idea.why, style: const TextStyle(height: 1.4)),
                  const SizedBox(height: 6),
                  Text(
                    'Care: ${idea.care}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                  if (profileTip(widget.profile, idea) case final tip?) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Tips for you: $tip',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.deepPink,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _HowTo(
                    idea: idea,
                    profile: widget.profile,
                    tutorials: _tutorialCache[idea.name],
                  ),
                ],
              ),
            ),
          ),
        if (_assistant.isAvailable) ...[
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: _loading ? null : _askAi,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              _aiIdeas == null ? 'Personalize with AI' : 'Regenerate with AI',
            ),
          ),
          if (_aiIdeas != null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'These ideas are AI-generated.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            _disclaimer,
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}

/// Short rule-based tip from the hair profile.
String? profileTip(HairProfile p, HairstyleIdea idea) {
  if (p.colorTreated) return 'skip high heat to protect your color.';
  if (p.strandSize == StrandSize.fine) {
    return 'use lighter products so fine strands stay bouncy.';
  }
  if (p.concerns.contains(HairConcern.breakage)) {
    return 'keep it loose and detangle gently when restyling.';
  }
  return switch (p.washFrequency) {
    WashFrequency.daily => 'wash daily? Rinse-only days keep moisture in.',
    WashFrequency.biweekly =>
      'washing every 2 weeks or less? Cleanse your scalp before restyling.',
    _ => null,
  };
}

class _HowTo extends StatelessWidget {
  const _HowTo({
    required this.idea,
    required this.profile,
    required this.tutorials,
  });

  final HairstyleIdea idea;
  final HairProfile profile;
  final List<HairstyleTutorial>? tutorials;

  @override
  Widget build(BuildContext context) {
    final ranked = rankTutorials(tutorials ?? const [], profile.curlPattern);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How to', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (ranked.isNotEmpty)
          SizedBox(
            height: 156,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ranked.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _TutorialTile(tutorial: ranked[i]),
            ),
          ),
        TextButton.icon(
          onPressed: () => launchUrl(
            youtubeSearchUri(idea.name, profile.curlPattern),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.search, size: 18),
          label: const Text('Search how-to videos'),
        ),
      ],
    );
  }
}

class _TutorialTile extends StatelessWidget {
  const _TutorialTile({required this.tutorial});

  final HairstyleTutorial tutorial;

  @override
  Widget build(BuildContext context) {
    const fallback = ColoredBox(
      color: AppColors.rose,
      child: Center(child: Icon(Icons.spa, color: AppColors.pink)),
    );
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
      onTap: () => openSource(tutorial.sourceUrl),
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
              child: SizedBox(
                height: 90,
                width: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (tutorial.thumbnailUrl.isEmpty)
                      fallback
                    else
                      Image.network(
                        tutorial.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => fallback,
                      ),
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tutorial.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, height: 1.25),
            ),
            Text(
              '${tutorial.platform == 'tiktok' ? 'TikTok' : 'YouTube'} · ${tutorial.sourceName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
