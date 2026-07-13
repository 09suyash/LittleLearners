import 'package:shared_preferences/shared_preferences.dart';

// Simple shared state — set by HomeScreen on load, read by game screens.
class AppState {
  static String mascot    = '🦉';
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

  // ── XP / Level system ──────────────────────────────────────────────────────
  // Thresholds: stars needed to START that level
  static const _thresholds = [0, 50, 150, 300, 500, 750];
  static const _names  = ['Explorer', 'Learner', 'Scholar', 'Champion', 'Master', 'Legend'];
  static const _emojis = ['⭐', '📚', '🎓', '🏆', '🌟', '🌈'];

  static int get level {
    for (int i = _thresholds.length - 1; i >= 0; i--) {
      if (totalStars >= _thresholds[i]) return i + 1;
    }
    return 1;
  }

  static String get levelName  => _names[level - 1];
  static String get levelEmoji => _emojis[level - 1];

  // 0.0 → 1.0 progress within the current level
  static double get levelProgress {
    final lv = level;
    if (lv >= _thresholds.length) return 1.0;
    final start = _thresholds[lv - 1];
    final end   = _thresholds[lv];
    return ((totalStars - start) / (end - start)).clamp(0.0, 1.0);
  }

  // Stars needed to reach next level (0 if already at max)
  static int get starsToNext {
    final lv = level;
    if (lv >= _thresholds.length) return 0;
    return _thresholds[lv] - totalStars;
  }
}
