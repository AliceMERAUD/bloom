import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloom/screens/sport/sport_screen.dart';
import 'package:bloom/services/workout_session_service.dart';

void main() {
  setUp(() {
    WorkoutSessionService.resetForTesting();
  });

  testWidgets('SportScreen affiche le catalogue d’exercices', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SportScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Sport'), findsOneWidget);
    expect(find.text('Traction'), findsOneWidget);
    expect(find.text('Pompes'), findsOneWidget);
  });
}
