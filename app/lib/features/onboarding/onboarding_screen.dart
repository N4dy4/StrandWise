import 'package:flutter/material.dart';

import '../../data/profile_store.dart';
import '../../models/hair_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/strand_motion.dart';

const _hairPatternGroups = [
  ('Straight', ['1A', '1B', '1C']),
  ('Wavy', ['2A', '2B', '2C']),
  ('Curly', ['3A', '3B', '3C']),
  ('Coily', ['4A', '4B', '4C']),
];

const _strandDescriptions = {
  StrandSize.fine: (
    'Fine',
    'A single strand is very thin, like thread. You can barely feel it between your fingers.',
  ),
  StrandSize.medium: (
    'Medium',
    'A strand feels like regular sewing thread. You can feel it, but it is not wiry.',
  ),
  StrandSize.coarse: (
    'Coarse',
    'A strand feels thick, strong or wiry between your fingers.',
  ),
};

const _densityDescriptions = {
  Density.thin: (
    'Thin',
    'Your scalp is easy to see, even when your hair is down.',
  ),
  Density.medium: (
    'Medium',
    'You can see your scalp a little when you part your hair.',
  ),
  Density.thick: (
    'Thick',
    'Your scalp is hard to see, and a ponytail or twist feels full.',
  ),
};

const _scalpDescriptions = {
  ScalpType.dry: ('Dry', 'Tight or flaky, and itchy between washes.'),
  ScalpType.balanced: ('Balanced', 'Comfortable, not very oily or dry.'),
  ScalpType.oily: ('Oily', 'Greasy or heavy again within a day or two.'),
};

const _concernLabels = {
  HairConcern.frizz: ('Frizz', 'Hair puffs up or loses its definition.'),
  HairConcern.breakage: ('Breakage', 'Snapping, split ends or short pieces.'),
  HairConcern.dandruff: ('Dandruff', 'Flakes or an itchy scalp.'),
  HairConcern.dryness: ('Dryness', 'Hair feels rough, brittle or thirsty.'),
  HairConcern.hairLoss: ('Hair loss', 'Thinning or shedding more than usual.'),
};

const _washDescriptions = {
  WashFrequency.daily: 'Every day',
  WashFrequency.fewDays: 'Every 2–4 days',
  WashFrequency.weekly: 'About once a week',
  WashFrequency.biweekly: 'Every 2 weeks or less',
};

const _stylingDescriptions = {
  HairStyling.out: 'Wear it out',
  HairStyling.braidsTwists: 'Braids / twists',
  HairStyling.wigs: 'Wigs / weaves',
  HairStyling.updos: 'Buns / updos',
  HairStyling.heatStyled: 'Heat styled (blow-dry, flat iron)',
};

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone, this.initial});

  final ValueChanged<HairProfile> onDone;
  final HairProfile? initial;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late String? _curl = widget.initial?.curlPattern;
  late StrandSize _strand = widget.initial?.strandSize ?? StrandSize.medium;
  late Density _density = widget.initial?.density ?? Density.medium;
  late ScalpType _scalp = widget.initial?.scalp ?? ScalpType.balanced;
  late HairConcern? _concern = widget.initial?.concerns.firstOrNull;
  late bool? _colorTreated = widget.initial?.colorTreated;
  late WashFrequency? _wash = widget.initial?.washFrequency;
  late final Set<HairStyling> _styling = {...?widget.initial?.styling};
  late final Porosity _porosity = widget.initial?.porosity ?? Porosity.medium;

  static const _titles = [
    'What should we call you?',
    'What is your curl pattern?',
    'How thick is each strand?',
    'How full is your hair?',
    'How is your scalp?',
    "What's your biggest hair concern?",
    'Is your hair color-treated?',
    'How often do you wash your hair?',
    'How do you usually wear your hair?',
  ];

  static const _subtitles = [
    'We will use it to welcome you. It stays on your device.',
    'This stays on your device and shapes your routine.',
    'Roll one strand between your fingers and pick what is closest.',
    'Pick the description that sounds most like you.',
    'Your scalp preferences help guide gentle care suggestions.',
    'Pick the one that bothers you most. You can change it anytime.',
    'Dyed, bleached, highlighted or chemically relaxed hair needs extra care.',
    'Your answer sets your wash-day schedule.',
    'Choose as many as apply.',
  ];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canContinue => switch (_step) {
    0 => _name.text.trim().isNotEmpty,
    1 => _curl != null,
    5 => _concern != null || _noConcern,
    6 => _colorTreated != null,
    7 => _wash != null,
    _ => true,
  };

  late var _noConcern =
      widget.initial != null && widget.initial!.concerns.isEmpty;

  String? get _selectedHairPatternGroup {
    for (final group in _hairPatternGroups) {
      if (group.$2.contains(_curl)) return group.$1;
    }
    return null;
  }

  Future<void> _next() async {
    if (_step < _titles.length - 1) {
      setState(() => _step++);
      return;
    }
    final profile = HairProfile(
      curlPattern: _curl!,
      name: _name.text.trim(),
      porosity: _porosity,
      density: _density,
      strandSize: _strand,
      scalp: _scalp,
      concerns: {?_concern},
      colorTreated: _colorTreated ?? false,
      washFrequency: _wash,
      styling: _styling,
    );
    await ProfileStore.save(profile);
    widget.onDone(profile);
  }

  Widget _options<T>({
    required List<(T, String, String?)> options,
    required bool Function(T) isSelected,
    required void Function(T) onPick,
  }) => Column(
    children: [
      for (final (value, label, description) in options)
        _OptionCard(
          label: label,
          description: description,
          selected: isSelected(value),
          onTap: () => setState(() => onPick(value)),
        ),
    ],
  );

  Widget _body() {
    switch (_step) {
      case 0:
        return TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: 'Your first name'),
          onChanged: (_) => setState(() {}),
        );
      case 1:
        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.35,
          children: [
            for (final group in _hairPatternGroups)
              _HairPatternCard(
                label: group.$1,
                selected: _selectedHairPatternGroup == group.$1,
                onTap: () => setState(() => _curl = group.$2.last),
              ),
          ],
        );
      case 2:
        return _options<StrandSize>(
          options: [
            for (final e in _strandDescriptions.entries)
              (e.key, e.value.$1, e.value.$2),
          ],
          isSelected: (v) => v == _strand,
          onPick: (v) => _strand = v,
        );
      case 3:
        return _options<Density>(
          options: [
            for (final e in _densityDescriptions.entries)
              (e.key, e.value.$1, e.value.$2),
          ],
          isSelected: (v) => v == _density,
          onPick: (v) => _density = v,
        );
      case 4:
        return _options<ScalpType>(
          options: [
            for (final e in _scalpDescriptions.entries)
              (e.key, e.value.$1, e.value.$2),
          ],
          isSelected: (v) => v == _scalp,
          onPick: (v) => _scalp = v,
        );
      case 5:
        return _options<HairConcern?>(
          options: [
            for (final e in _concernLabels.entries)
              (e.key, e.value.$1, e.value.$2),
            (null, 'None right now', 'Just keeping my hair healthy.'),
          ],
          isSelected: (v) => v == null ? _noConcern : v == _concern,
          onPick: (v) {
            _concern = v;
            _noConcern = v == null;
          },
        );
      case 6:
        return _options<bool>(
          options: const [
            (true, 'Yes', 'Dyed, bleached, highlighted or relaxed.'),
            (false, 'No', 'Natural, untreated color.'),
          ],
          isSelected: (v) => v == _colorTreated,
          onPick: (v) => _colorTreated = v,
        );
      case 7:
        return _options<WashFrequency>(
          options: [
            for (final e in _washDescriptions.entries) (e.key, e.value, null),
          ],
          isSelected: (v) => v == _wash,
          onPick: (v) => _wash = v,
        );
      default:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in _stylingDescriptions.entries)
              FilterChip(
                label: Text(e.value),
                selected: _styling.contains(e.key),
                onSelected: (on) => setState(
                  () => on ? _styling.add(e.key) : _styling.remove(e.key),
                ),
              ),
          ],
        );
    }
  }

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
            TweenAnimationBuilder<double>(
              tween: Tween(end: (_step + 1) / _titles.length),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 28),
            FadeSlideIn(
              key: ValueKey('heading$_step'),
              duration: const Duration(milliseconds: 350),
              offset: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titles[_step],
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _subtitles[_step],
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: FadeSlideIn(
                  key: ValueKey('body$_step'),
                  delay: const Duration(milliseconds: 80),
                  duration: const Duration(milliseconds: 350),
                  child: _body(),
                ),
              ),
            ),
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

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
  });

  final String label;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.rose : AppColors.cream,
            borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
            border: Border.all(
              color: selected ? AppColors.pink : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description!,
                  style: const TextStyle(color: AppColors.muted, height: 1.35),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _HairPatternCard extends StatelessWidget {
  const _HairPatternCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: InkWell(
      borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.rose : AppColors.cream,
          borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
          border: Border.all(
            color: selected ? AppColors.pink : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              Icons.water_drop_outlined,
              color: selected ? AppColors.pink : AppColors.muted,
            ),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    ),
  );
}
