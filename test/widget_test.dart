import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FlutterBlueApp());

    // Verify that the app shows the main title.
    expect(find.text('Поиск Bluetooth устройств'), findsOneWidget);
  });
}
