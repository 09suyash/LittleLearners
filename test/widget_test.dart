import 'package:flutter_test/flutter_test.dart';
import 'package:zoodles/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ZoodlesApp());
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('HOME'), findsOneWidget);
  });
}
