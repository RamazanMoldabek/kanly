import 'package:flutter_test/flutter_test.dart';
import 'package:kanly/main.dart';

void main() {
  testWidgets('KanlyApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KanlyApp());

    // Verify that our config check text is present.
    expect(find.text('Env & Supabase Configured!'), findsOneWidget);
  });
}
