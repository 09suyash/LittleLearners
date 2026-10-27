import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoodles/main.dart';
import 'package:zoodles/features/games/screens/coloring_book_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'child_name': 'Alex'});
  });

  testWidgets('App smoke test & Tab navigation across all decomposed screens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ZoodlesApp());
    // Pump past splash screen timer (3 seconds)
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 500));

    // 1. Home screen verification
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('Hi, Alex! 👋'), findsWidgets);
    expect(find.text('ABC & Phonics'), findsOneWidget);
    expect(find.text('Math Quiz'), findsOneWidget);
    expect(find.text('Moral Stories'), findsOneWidget);

    // 2. Switch to ABC Tab using bottom nav item
    final abcNavItem = find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text('ABC'),
    );
    await tester.tap(abcNavItem);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('ABC & Phonics Pro'), findsOneWidget);
    expect(find.text('Letters Learned'), findsOneWidget);

    // 3. Switch to MATH Tab using bottom nav item
    final mathNavItem = find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text('MATH'),
    );
    await tester.tap(mathNavItem);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Math Quiz Pro'), findsOneWidget);
    expect(find.text('Practice'), findsOneWidget);
    expect(find.text('Times Tables'), findsOneWidget);
    expect(find.text('⚡ Blitz! 60s'), findsOneWidget);

    // 4. Switch to STORIES Tab using bottom nav item
    final storiesNavItem = find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text('STORIES'),
    );
    await tester.tap(storiesNavItem);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Moral Stories'), findsOneWidget);
  });

  testWidgets('ColoringBookScreen mounts and renders canvas and tools', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ColoringBookScreen(onBack: () {}),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Coloring Book'), findsOneWidget);
    expect(find.text('Choose Design'), findsOneWidget);
    expect(find.text('Brush'), findsOneWidget);
    expect(find.text('Fill'), findsOneWidget);
    expect(find.text('Eraser'), findsOneWidget);
  });
}
