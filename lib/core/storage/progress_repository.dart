import 'package:shared_preferences/shared_preferences.dart';
import '../services/badge_service.dart';
import '../services/daily_challenge_service.dart';
import '../state/app_state.dart';
import 'storage_keys.dart';

/// Data class holding overall learning summary for dashboard screens.
class ProgressOverview {
  final int abcLearned;
  final int mathBest;
  final int mathBestTotal;
  final int blitzBest;
  final int storiesRead;
  final String childName;
  final int totalStars;

  const ProgressOverview({
    required this.abcLearned,
    required this.mathBest,
    required this.mathBestTotal,
    required this.blitzBest,
    required this.storiesRead,
    required this.childName,
    required this.totalStars,
  });
}

/// Central repository managing user progress, scores, and offline persistence.
/// Provides a single point of truth across the app and abstracts SharedPreferences.
class ProgressRepository {
  static final ProgressRepository _instance = ProgressRepository._();
  factory ProgressRepository() => _instance;
  ProgressRepository._();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ── Child Profile & Settings ──────────────────────────────────────────────

  Future<String> getChildName() async {
    final p = await _prefs;
    return p.getString(StorageKeys.childName) ?? '';
  }

  Future<void> setChildName(String name) async {
    final p = await _prefs;
    await p.setString(StorageKeys.childName, name);
    AppState.childName = name;
  }

  Future<String?> getParentPin() async {
    final p = await _prefs;
    return p.getString(StorageKeys.parentPin);
  }

  Future<void> setParentPin(String pin) async {
    final p = await _prefs;
    await p.setString(StorageKeys.parentPin, pin);
  }

  Future<void> removeParentPin() async {
    final p = await _prefs;
    await p.remove(StorageKeys.parentPin);
  }

  // ── ABC Learning Progress ─────────────────────────────────────────────────

  Future<List<String>> getAbcLearnedLetters() async {
    final p = await _prefs;
    return p.getStringList(StorageKeys.abcLearnedLetters) ?? [];
  }

  Future<int> getAbcLearnedCount() async {
    final p = await _prefs;
    return p.getInt(StorageKeys.abcLearned) ?? 0;
  }

  Future<int?> getAbcQuizBest() async {
    final p = await _prefs;
    return p.getInt(StorageKeys.abcQuizBest);
  }

  Future<void> saveAbcProgress({
    required List<String> learnedLetters,
    int? quizBest,
  }) async {
    final p = await _prefs;
    await p.setStringList(StorageKeys.abcLearnedLetters, learnedLetters);
    await p.setInt(StorageKeys.abcLearned, learnedLetters.length);
    if (quizBest != null) {
      await p.setInt(StorageKeys.abcQuizBest, quizBest);
    }
  }

  // ── Math Quiz & Blitz Progress ────────────────────────────────────────────

  Future<int> getMathBest() async {
    final p = await _prefs;
    return p.getInt(StorageKeys.mathBest) ?? -1;
  }

  Future<int> getMathBestTotal() async {
    final p = await _prefs;
    return p.getInt(StorageKeys.mathBestTotal) ?? 10;
  }

  Future<int> getBlitzBest() async {
    final p = await _prefs;
    return p.getInt(StorageKeys.blitzBest) ?? 0;
  }

  Future<bool> saveMathScore({required int score, required int total}) async {
    final p = await _prefs;
    final prev = p.getInt(StorageKeys.mathBest) ?? -1;
    if (score > prev) {
      await p.setInt(StorageKeys.mathBest, score);
      await p.setInt(StorageKeys.mathBestTotal, total);
      return true;
    }
    return false;
  }

  Future<int> saveBlitzScore(int score) async {
    final p = await _prefs;
    final prev = p.getInt(StorageKeys.blitzBest) ?? -1;
    if (score > prev) {
      await p.setInt(StorageKeys.blitzBest, score);
      return score;
    }
    return prev > 0 ? prev : score;
  }

  // ── Moral Stories Progress ────────────────────────────────────────────────

  Future<List<String>> getCompletedStoryIds() async {
    final p = await _prefs;
    return p.getStringList(StorageKeys.storiesDone) ?? [];
  }

  Future<void> markStoryCompleted(int storyId) async {
    final p = await _prefs;
    final current = Set<String>.from(p.getStringList(StorageKeys.storiesDone) ?? []);
    current.add('$storyId');
    await p.setStringList(StorageKeys.storiesDone, current.toList());
  }

  // ── Cross-Feature Milestones ──────────────────────────────────────────────

  Future<bool> hasExploredAllApps() async {
    final p = await _prefs;
    final hasAbc = (p.getInt(StorageKeys.abcLearned) ?? 0) > 0;
    final hasMath = (p.getInt(StorageKeys.mathBest) ?? -1) >= 0;
    final hasStories = (p.getStringList(StorageKeys.storiesDone) ?? []).isNotEmpty;
    return hasAbc && hasMath && hasStories;
  }

  // ── Dashboard Overview ────────────────────────────────────────────────────

  Future<ProgressOverview> getOverview() async {
    final p = await _prefs;
    return ProgressOverview(
      abcLearned: p.getInt(StorageKeys.abcLearned) ?? 0,
      mathBest: p.getInt(StorageKeys.mathBest) ?? -1,
      mathBestTotal: p.getInt(StorageKeys.mathBestTotal) ?? 10,
      blitzBest: p.getInt(StorageKeys.blitzBest) ?? 0,
      storiesRead: p.getStringList(StorageKeys.storiesDone)?.length ?? 0,
      childName: p.getString(StorageKeys.childName) ?? '',
      totalStars: p.getInt(StorageKeys.totalStars) ?? 0,
    );
  }

  // ── Mini-Games High Scores ────────────────────────────────────────────────

  Future<({int best, int total, String? animal})> getAnimalFeedingStats({int defaultTotal = 10}) async {
    final p = await _prefs;
    return (
      best: p.getInt(StorageKeys.feedingBest) ?? -1,
      total: p.getInt(StorageKeys.feedingBestTotal) ?? defaultTotal,
      animal: p.getString(StorageKeys.feedingAnimal),
    );
  }

  Future<void> saveAnimalFeedingStats({
    required int score,
    required int total,
    required String animal,
  }) async {
    final p = await _prefs;
    await p.setString(StorageKeys.feedingAnimal, animal);
    final prev = p.getInt(StorageKeys.feedingBest) ?? -1;
    if (score > prev) {
      await p.setInt(StorageKeys.feedingBest, score);
      await p.setInt(StorageKeys.feedingBestTotal, total);
    }
  }

  Future<({int level, int endless})> getMazeStats() async {
    final p = await _prefs;
    return (
      level: p.getInt(StorageKeys.mazeBestLevel) ?? 0,
      endless: p.getInt(StorageKeys.mazeEndlessLevel) ?? 0,
    );
  }

  Future<void> saveMazeLevel(int level) async {
    final p = await _prefs;
    await p.setInt(StorageKeys.mazeBestLevel, level);
  }

  Future<void> saveMazeEndless(int level) async {
    final p = await _prefs;
    await p.setInt(StorageKeys.mazeEndlessLevel, level);
  }

  Future<int> getSimonBestRound() async {
    final p = await _prefs;
    return p.getInt(StorageKeys.simonBestRound) ?? 0;
  }

  Future<void> saveSimonBestRound(int round) async {
    final p = await _prefs;
    await p.setInt(StorageKeys.simonBestRound, round);
  }

  Future<int> getWhackBestScore() async {
    final p = await _prefs;
    return p.getInt(StorageKeys.whackBestScore) ?? 0;
  }

  Future<void> saveWhackBestScore(int score) async {
    final p = await _prefs;
    await p.setInt(StorageKeys.whackBestScore, score);
  }

  Future<int> getBubbleBestScore() async {
    final p = await _prefs;
    return p.getInt(StorageKeys.bubbleBestScore) ?? 0;
  }

  Future<void> saveBubbleBestScore(int score) async {
    final p = await _prefs;
    await p.setInt(StorageKeys.bubbleBestScore, score);
  }

  Future<({int best, int total})> getArcheryStats({int defaultTotal = 10}) async {
    final p = await _prefs;
    return (
      best: p.getInt(StorageKeys.archeryBest) ?? -1,
      total: p.getInt(StorageKeys.archeryBestTotal) ?? defaultTotal,
    );
  }

  Future<void> saveArcheryStats({required int score, required int total}) async {
    final p = await _prefs;
    final prev = p.getInt(StorageKeys.archeryBest) ?? -1;
    if (score > prev) {
      await p.setInt(StorageKeys.archeryBest, score);
      await p.setInt(StorageKeys.archeryBestTotal, total);
    }
  }

  Future<({int best, int total})> getAnimalSoundStats({int defaultTotal = 10}) async {
    final p = await _prefs;
    return (
      best: p.getInt(StorageKeys.animalBest) ?? -1,
      total: p.getInt(StorageKeys.animalBestTotal) ?? defaultTotal,
    );
  }

  Future<void> saveAnimalSoundStats({required int score, required int total}) async {
    final p = await _prefs;
    final prev = p.getInt(StorageKeys.animalBest) ?? -1;
    if (score > prev) {
      await p.setInt(StorageKeys.animalBest, score);
      await p.setInt(StorageKeys.animalBestTotal, total);
    }
  }

  Future<String?> getRacingVehicle() async {
    final p = await _prefs;
    return p.getString(StorageKeys.racingVehicle);
  }

  Future<void> saveRacingVehicle(String vehicle) async {
    final p = await _prefs;
    await p.setString(StorageKeys.racingVehicle, vehicle);
  }

  // ── Reset All Progress ───────────────────────────────────────────────────

  /// Clears all local game progress, badges, daily streaks, and stars.
  Future<void> resetAll() async {
    final p = await _prefs;
    await p.clear();
    await BadgeService().clear();
    await DailyChallengeService().clear();
    AppState.totalStars = 0;
    AppState.childName = '';
  }
}
