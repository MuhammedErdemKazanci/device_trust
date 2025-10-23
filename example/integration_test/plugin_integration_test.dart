// Integration test for device_trust plugin
// Simple smoke test to ensure basic functionality works
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:device_trust_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches and button is visible',
      (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const DeviceTrustExampleApp());

    // Wait for initial render
    await tester.pumpAndSettle();

    // Verify the main button exists
    expect(find.text('Get DeviceTrust Report'), findsOneWidget);

    // Verify initial message is shown
    expect(
      find.text('Tap the button above to collect device trust signals.'),
      findsOneWidget,
    );
  });
}
