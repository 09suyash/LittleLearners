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

  @override
  void dispose() {
    _tabNotifier.dispose();
    super.dispose();
  }

  void goToTab(int idx) {
    setState(() => _tab = idx);
    _tabNotifier.value = idx;
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onTabSelected: goToTab, tabNotifier: _tabNotifier),
      const AbcScreen(),
      const MathScreen(),
      const StoriesScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0f0c29),
      body: IndexedStack(index: _tab, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: goToTab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0a1628),
        selectedItemColor: const Color(0xFFFFD93D),
        unselectedItemColor: Colors.white38,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 2), child: Text('🏠', style: TextStyle(fontSize: 22))),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 2), child: Text('🔤', style: TextStyle(fontSize: 22))),
            label: 'ABC',
          ),
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 2), child: Text('🔢', style: TextStyle(fontSize: 22))),
            label: 'MATH',
          ),
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 2), child: Text('📚', style: TextStyle(fontSize: 22))),
            label: 'STORIES',
          ),
        ],
      ),
    );
  }
}
