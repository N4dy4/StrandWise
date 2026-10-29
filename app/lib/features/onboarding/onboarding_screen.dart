import 'package:flutter/material.dart';

import '../../data/profile_store.dart';
import '../../models/hair_profile.dart';
import '../../theme/app_theme.dart';

const _curlPatterns = [
  '1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B', '4C', //
];

String _label(Enum e) => e.name[0].toUpperCase() + e.name.substring(1);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone, this.initial});

  final ValueChanged<HairProfile> onDone;
  final HairProfile? initial;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  late String? _curl = widget.initial?.curlPattern;
  late Porosity _porosity = widget.initial?.porosity ?? Porosity.medium;
  late Density _density = widget.initial?.density ?? Density.medium;
  late ScalpType _scalp = widget.initial?.scalp ?? ScalpType.balanced;
  late final Set<HairConcern> _concerns = {...?widget.initial?.concerns};

  static const _titles = [
    'What is your curl pattern?',
    'How porous is your hair?',
    'How dense is your hair?',
    'How is your scalp?',
    'Any concerns?',
  ];

  bool get _canContinue => _step != 0 || _curl != null;

  Future<void> _next() async {
    if (_step < _titles.length - 1) {
      setState(() => _step++);
      return;
    }
    final profile = HairProfile(
      curlPattern: _curl!,
      porosity: _porosity,
      density: _density,
      scalp: _scalp,
      concerns: _concerns,
    );
    await ProfileStore.save(profile);
    widget.onDone(profile);
  }

  Widget _choices<T extends Enum>(
      List<T> values, T selected, ValueChanged<T> onPick,
      {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hint != null)
          Padding(
              padding: const EdgeInsets.only(bottom: 12), child: Text(hint)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in values)
              ChoiceChip(
                label: Text(_label(v)),
                selected: v == selected,
                onSelected: (_) => setState(() => onPick(v)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _body() {
    switch (_step) {
      case 0:
        return Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in _curlPatterns)
            ChoiceChip(
              label: Text(c),
              selected: _curl == c,
              onSelected: (_) => setState(() => _curl = c),
            ),
        ]);
      case 1:
        return _choices(Porosity.values, _porosity, (v) => _porosity = v,
            hint: 'Low: water beads up. High: absorbs fast but dries fast.');
      case 2:
        return _choices(Density.values, _density, (v) => _density = v,
            hint: 'How much hair you have per square inch.');
      case 3:
        return _choices(ScalpType.values, _scalp, (v) => _scalp = v);
      default:
        return Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in HairConcern.values)
            FilterChip(
              label: Text(c == HairConcern.hairLoss ? 'Hair loss' : _label(c)),
              selected: _concerns.contains(c),
              onSelected: (on) => setState(
                  () => on ? _concerns.add(c) : _concerns.remove(c)),
            ),
        ]);
    }
  }

  String get _subtitle => switch (_step) {
        0 => 'This stays on your device and shapes your routine.',
        1 => 'Low: water beads up. High: absorbs fast but dries fast.',
        2 => 'This helps tailor product textures and wash-day steps.',
        3 => 'Your scalp preferences help guide gentle care suggestions.',
        _ => 'Choose as many as apply. You can update these anytime.',
      };

  @override
  Widget build(BuildContext context) {
    final last = _step == _titles.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: Text('${_step + 1} of ${_titles.length}'),
        leading: _step > 0
            ? BackButton(onPressed: () => setState(() => _step--))
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
                value: (_step + 1) / _titles.length,
                borderRadius: BorderRadius.circular(8)),
            const SizedBox(height: 24),
            const SizedBox(height: 28),
            Text(_titles[_step], style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(_subtitle, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 24),
            Expanded(child: SingleChildScrollView(child: _body())),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canContinue ? _next : null,
                child: Text(last ? 'Build my routine' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
