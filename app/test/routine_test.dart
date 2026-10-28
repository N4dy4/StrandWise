import 'package:flutter_test/flutter_test.dart';
import 'package:strandwise/models/hair_profile.dart';
import 'package:strandwise/services/routine_engine.dart';

void main() {
  test('wash frequency follows curl family, scalp and dandruff', () {
    expect(RoutineEngine.washFrequency(const HairProfile(curlPattern: '4C')),
        'Every 7 days');
    expect(
        RoutineEngine.washFrequency(
            const HairProfile(curlPattern: '4C', scalp: ScalpType.oily)),
        'Every 6 days');
    expect(
        RoutineEngine.washFrequency(const HairProfile(
            curlPattern: '4C', concerns: {HairConcern.dandruff})),
        'Every 4 days');
  });

  test('wash day adapts to porosity and concerns', () {
    final low = RoutineEngine.washDay(
        const HairProfile(curlPattern: '3B', porosity: Porosity.low));
    final high = RoutineEngine.washDay(const HairProfile(
        curlPattern: '3B',
        porosity: Porosity.high,
        concerns: {HairConcern.frizz}));
    List<String> titles(Routine r) => r.steps.map((s) => s.title).toList();
    expect(titles(low), isNot(contains('Deep treatment')));
    expect(titles(high), containsAll(['Deep treatment', 'Anti-frizz']));
  });

  test('HairProfile JSON round trip', () {
    const p = HairProfile(
        curlPattern: '2C',
        porosity: Porosity.high,
        concerns: {HairConcern.hairLoss});
    final q = HairProfile.decode(p.encode());
    expect(q.curlPattern, '2C');
    expect(q.porosity, Porosity.high);
    expect(q.concerns, {HairConcern.hairLoss});
  });
}
