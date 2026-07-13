import 'package:flutter_test/flutter_test.dart';
import 'package:zoodles/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ZoodlesApp());
    expect(find.text('HOME'), findsOneWidget);
  });
}
