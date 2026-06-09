import 'package:flutter_test/flutter_test.dart';
import 'package:kids_learning_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KidsLearningApp());
    expect(find.text('HOME'), findsOneWidget);
  });
}
