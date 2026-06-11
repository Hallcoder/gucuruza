import 'package:flutter_test/flutter_test.dart';
import 'package:gucuruza/main.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(const GucuruzaApp());
    expect(find.text('Gucuruza'), findsOneWidget);
  });
}
