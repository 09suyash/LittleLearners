import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/abc_screen.dart';
import 'screens/math_screen.dart';
import 'screens/stories_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const KidsLearningApp());
}

class KidsLearningApp extends StatelessWidget {
  const KidsLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Little Learners',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD93D),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      builder: (context, child) => DefaultTextStyle.merge(
        style: const TextStyle(decoration: TextDecoration.none),
        child: child!,
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  final _tabNotifier = ValueNotifier<int>(0);

  // Nested navigator for the home tab so all pushed screens
  // (Memory Match, Word Builder, etc.) stay inside it and the
  // bottom nav bar remains visible.
  final _homeNavKey = GlobalKey<NavigatorState>();

  @override
  void dispose() {
    _tabNotifier.dispose();
    super.dispose();
  }

  void goToTab(int idx) {
    // Always pop the home navigator back to its root before any tab switch,
    // so the home screen is clean if the user returns to it later.
    _homeNavKey.currentState?.popUntil((r) => r.isFirst);
    if (idx == _tab) return;
    setState(() => _tab = idx);
    _tabNotifier.value = idx;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Delegate back gesture to the home tab's nested navigator first
        if (_homeNavKey.currentState?.canPop() ?? false) {
          if (_tab != 0) setState(() => _tab = 0);
          _homeNavKey.currentState!.pop();
          return;
        }
        // On a non-home tab, back goes to home
        if (_tab != 0) {
          goToTab(0);
        }
        // On home tab at root — do nothing (prevents accidental app close for kids)
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0f0c29),
      body: IndexedStack(
        index: _tab,
        children: [
          // Home tab uses a nested Navigator so pushed sub-screens
          // (games, challenges, badges, parent dashboard) are contained
          // within tab 0 and the bottom nav stays visible throughout.
          Navigator(
            key: _homeNavKey,
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => HomeScreen(
                onTabSelected: goToTab,
                tabNotifier: _tabNotifier,
              ),
            ),
          ),
          AbcScreen(onGoHome: () => goToTab(0)),
          MathScreen(onGoHome: () => goToTab(0)),
          StoriesScreen(onGoHome: () => goToTab(0)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: goToTab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0a1628),
        selectedItemColor: const Color(0xFFFFD93D),
        unselectedItemColor: Colors.white38,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: [
          BottomNavigationBarItem(
            icon: Opacity(opacity: 0.45, child: Image.asset('assets/images/trophy_card.png', width: 30, height: 30, fit: BoxFit.contain)),
            activeIcon: Image.asset('assets/images/home_card.png', width: 30, height: 30, fit: BoxFit.contain),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Opacity(opacity: 0.45, child: Image.asset('assets/images/abc_card.png', width: 30, height: 30, fit: BoxFit.contain)),
            activeIcon: Image.asset('assets/images/abc_card.png', width: 30, height: 30, fit: BoxFit.contain),
            label: 'ABC',
          ),
          BottomNavigationBarItem(
            icon: Opacity(opacity: 0.45, child: Image.asset('assets/images/math_card.png', width: 30, height: 30, fit: BoxFit.contain)),
            activeIcon: Image.asset('assets/images/math_card.png', width: 30, height: 30, fit: BoxFit.contain),
            label: 'MATH',
          ),
          BottomNavigationBarItem(
            icon: Opacity(opacity: 0.45, child: Image.asset('assets/images/stories_card.png', width: 30, height: 30, fit: BoxFit.contain)),
            activeIcon: Image.asset('assets/images/stories_card.png', width: 30, height: 30, fit: BoxFit.contain),
            label: 'STORIES',
          ),
        ],
      ),
      ),
    );
  }
}
