import 'package:shared_preferences/shared_preferences.dart';

// Simple shared state — set by HomeScreen on load, read by game screens.
class AppState {
  static String mascot   = '🦉';
  static String childName = '';
  static int totalStars   = 0;

  static Future<void> loadStars() async {
    final p = await SharedPreferences.getInstance();
    totalStars = p.getInt('total_stars') ?? 0;
  }

  static Future<void> addStars(int n) async {
    totalStars += n;
    final p = await SharedPreferences.getInstance();
    await p.setInt('total_stars', totalStars);
  }
}
