import 'package:flutter_test/flutter_test.dart';
import 'package:device_trust_example/main.dart';

void main() {
  testWidgets('App renders with button and initial message',
      (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const DeviceTrustExampleApp());

    // Verify button exists
    expect(find.text('Get DeviceTrust Report'), findsOneWidget);

    // Verify initial state message
    expect(
      find.text('Tap the button above to collect device trust signals.'),
      findsOneWidget,
    );
  });
}
