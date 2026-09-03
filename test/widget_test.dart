import 'package:flutter_test/flutter_test.dart';

import 'package:arrogame/main.dart';

void main() {
  testWidgets('Arrow Game app starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ArrowGameApp());
    await tester.pump();

    expect(find.text('LEVELS'), findsOneWidget);
  });
}
