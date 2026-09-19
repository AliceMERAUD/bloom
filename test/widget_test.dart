import 'package:flutter_test/flutter_test.dart';

import 'package:bloom/app/app.dart';

void main() {
  testWidgets('Bloom démarre correctement', (WidgetTester tester) async {
    await tester.pumpWidget(const BloomApp());

    expect(find.text('Bloom'), findsOneWidget);
    expect(find.text('Sport'), findsOneWidget);
    expect(find.text('Bien-être'), findsOneWidget);
    expect(find.text('Puzzle'), findsOneWidget);
  });
}
