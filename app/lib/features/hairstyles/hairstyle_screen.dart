import 'package:flutter/material.dart';

import '../../models/hair_profile.dart';
import '../../services/ai_assistant.dart';
import '../../services/hairstyle_recommender.dart';
import '../../theme/app_theme.dart';

const _disclaimer =
    'Hair care ideas only. Not medical advice; see a doctor for scalp or hair loss concerns.';

class HairstyleScreen extends StatefulWidget {
  const HairstyleScreen({super.key, required this.profile, this.assistant});

  final HairProfile profile;
  final AiAssistant? assistant;

  @override
  State<HairstyleScreen> createState() => _HairstyleScreenState();
}

class _HairstyleScreenState extends State<HairstyleScreen> {
  late final AiAssistant _assistant = widget.assistant ?? AiAssistant.create();
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

  void _toggle(StyleGoal goal, bool on) => setState(() {
    on ? _goals.add(goal) : _goals.remove(goal);
    _aiIdeas = null;
  });

  @override
  Widget build(BuildContext context) {
    final ideas =
        _aiIdeas ?? HairstyleRecommender.recommend(widget.profile, _goals);
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
