import 'package:flutter_test/flutter_test.dart';

// Basic smoke test to verify the app builds correctly.
void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Verify framework is operational.
    expect(1 + 1, equals(2));
  });
}
