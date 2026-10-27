/// Centralized constants for all local storage / SharedPreferences keys.
abstract class StorageKeys {
  // Global & Profiles
  static const String totalStars = 'total_stars';
  static const String childName = 'child_name';
  static const String parentPin = 'parent_pin';
  static const String earnedBadges = 'earned_badges';

  // Daily Challenge
  static const String dailyChallengeDate = 'dc_date';
  static const String dailyChallengeDone = 'dc_done';
  static const String dailyChallengeStreak = 'dc_streak';
  static const String dailyChallengeLastDate = 'dc_last_streak_date';

  // ABC
  static const String abcLearnedLetters = 'abc_learned_letters';
  static const String abcLearned = 'abc_learned';
  static const String abcQuizBest = 'abc_quiz_best';

  // Math
  static const String mathBest = 'math_best';
  static const String mathBestTotal = 'math_best_total';
  static const String blitzBest = 'blitz_best';

  // Stories
  static const String storiesDone = 'stories_done';
  static const String customStories = 'custom_stories_v1';

  // Mini-Games
  static const String feedingAnimal = 'feeding_animal';
  static const String feedingBest = 'feeding_best';
  static const String feedingBestTotal = 'feeding_best_total';
  static const String mazeBestLevel = 'maze_best_level';
  static const String mazeEndlessLevel = 'maze_endless_level';
  static const String simonBestRound = 'simon_best_round';
  static const String whackBestScore = 'whack_best_score';
  static const String bubbleBestScore = 'bubble_best_score';
  static const String archeryBest = 'archery_best';
  static const String archeryBestTotal = 'archery_best_total';
  static const String animalBest = 'animal_best';
  static const String animalBestTotal = 'animal_best_total';
  static const String racingVehicle = 'racing_vehicle';
}
