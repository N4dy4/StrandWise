import '../models/hair_profile.dart';

class RoutineStep {
  const RoutineStep(this.title, this.detail);
  final String title;
  final String detail;
}

class Routine {
  const Routine({
    required this.name,
    required this.frequency,
    required this.steps,
  });
  final String name;
  final String frequency;
  final List<RoutineStep> steps;
}

/// Rule-based routine templates: hair type x porosity x concerns (v1, no ML).
abstract final class RoutineEngine {
  static int _family(HairProfile p) =>
      int.tryParse(p.curlPattern.isEmpty ? '' : p.curlPattern[0]) ?? 2;

  static String washFrequency(HairProfile p) {
    final fam = _family(p);
    var days = switch (fam) { 1 => 2, 2 => 3, 3 => 5, _ => 7 };
    if (p.scalp == ScalpType.oily) days -= 1;
    if (p.scalp == ScalpType.dry) days += 1;
    if (p.concerns.contains(HairConcern.dandruff)) days = days.clamp(2, 4);
    days = days.clamp(2, 10);
    return 'Every $days days';
  }

  static Routine washDay(HairProfile p) {
    final c = p.concerns;
    final curly = _family(p) >= 3;
    final steps = <RoutineStep>[
      if (curly || c.contains(HairConcern.breakage))
        const RoutineStep('Pre-poo',
            'Apply a light oil or conditioner to dry hair for 15–20 min to reduce wash-day breakage.'),
      RoutineStep(
        p.scalp == ScalpType.oily || c.contains(HairConcern.dandruff)
            ? 'Cleanse (scalp-focused)'
            : 'Gentle cleanse',
        curly
            ? 'Use a sulfate-free shampoo on the scalp; let suds rinse down the lengths.'
            : 'Shampoo the scalp, avoiding rough scrubbing of the lengths.',
      ),
      if (c.contains(HairConcern.dandruff))
        const RoutineStep('Scalp care',
            'Use a gentle anti-dandruff shampoo as directed. See a doctor if it persists.'),
      RoutineStep(
        'Condition',
        p.porosity == Porosity.high || c.contains(HairConcern.dryness)
            ? 'Use a rich conditioner; detangle gently with fingers or a wide-tooth comb.'
            : 'Use a lightweight conditioner and detangle gently.',
      ),
      if (p.porosity == Porosity.high || c.contains(HairConcern.breakage))
        const RoutineStep('Deep treatment',
            'Add a protein/moisture mask every 2–4 washes, following the label.'),
      RoutineStep(
        'Seal & style',
        p.porosity == Porosity.low
            ? 'Use a lightweight leave-in and gel on damp hair; avoid heavy butters.'
            : 'Apply leave-in, then an oil or cream to seal in moisture.',
      ),
      if (c.contains(HairConcern.frizz))
        const RoutineStep('Anti-frizz',
            "Don't touch while drying; diffuse or air-dry, then scrunch out the cast."),
    ];
    return Routine(name: 'Wash day', frequency: washFrequency(p), steps: steps);
  }

  static Routine daily(HairProfile p) {
    final c = p.concerns;
    return Routine(name: 'Daily care', frequency: 'Daily', steps: [
      RoutineStep(
          'Refresh',
          _family(p) >= 3
              ? 'Mist with water and a little leave-in to revive curls.'
              : 'Lightly smooth with a damp hand or brush.'),
      if (c.contains(HairConcern.dryness) || p.porosity == Porosity.high)
        const RoutineStep('Moisturize', 'Add a small amount of cream to dry ends.'),
      const RoutineStep('Protect at night',
          'Use a satin bonnet or pillowcase to reduce friction and breakage.'),
    ]);
  }

  static List<Routine> build(HairProfile p) => [washDay(p), daily(p)];
}
