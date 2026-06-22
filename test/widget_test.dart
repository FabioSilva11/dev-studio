import 'package:flutter_test/flutter_test.dart';

import 'package:dev_studio/main.dart';
import 'package:dev_studio/main_screen.dart';

void main() {
  testWidgets('shows the splash and then opens the main screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DevStudioApp());

    expect(find.text('Dev Studio'), findsOneWidget);
    expect(find.text('Entre no incrível mundo Dev!'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Store'), findsNothing);
  });
}
