import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strandwise/data/local_content_repository.dart';
import 'package:strandwise/features/routine/routine_screen.dart';
import 'package:strandwise/models/hair_profile.dart';
import 'package:strandwise/services/ai_assistant.dart';
import 'package:strandwise/services/hairstyle_recommender.dart';

class _Ai implements AiAssistant {
  _Ai({this.fail = false});
  final bool fail;

  @override
  bool get isAvailable => true;

  @override
  Future<AiAnswer> ask(String question, HairProfile profile) async {
    if (fail) throw StateError('down');
    return const AiAnswer(text: 'Focus on moisture this week.');
  }

  @override
  Future<List<HairstyleIdea>> hairstyles(
    HairProfile profile,
    Set<StyleGoal> goals,
  ) async => const [];
}

Future<void> _pump(WidgetTester tester, AiAssistant ai) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: RoutineScreen(
        profile: const HairProfile(curlPattern: '4C', name: 'Ada'),
        repository: LocalContentRepository(),
        assistant: ai,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home shows AI plan, feed picks and style ideas', (tester) async {
    await _pump(tester, _Ai());
    expect(find.text('Focus on moisture this week.'), findsOneWidget);
    expect(find.text('From your feed'), findsOneWidget);
    expect(find.text('Style ideas'), findsOneWidget);
    expect(find.textContaining('Full routine'), findsOneWidget);
  });

  testWidgets('home falls back to rule-based routine when AI fails', (
    tester,
  ) async {
    await _pump(tester, _Ai(fail: true));
    expect(find.textContaining('AI tips are unavailable'), findsOneWidget);
    expect(find.textContaining('Full routine'), findsOneWidget);
  });
}
