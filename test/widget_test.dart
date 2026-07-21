import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusly/main.dart';

void main() {
  testWidgets('Campusly app smoke test', (WidgetTester tester) async {
    // Build our app inside ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: CampuslyApp()));

    // Verify that the splash screen title or logo renders without crashing.
    expect(find.text('Campusly'), findsOneWidget);
  });
}
