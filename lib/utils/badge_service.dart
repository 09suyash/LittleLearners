import 'package:shared_preferences/shared_preferences.dart';

class BadgeDef {
  final String id;
  final String emoji;
  final String name;
  final String desc;
  const BadgeDef({required this.id, required this.emoji, required this.name, required this.desc});
}

const allBadges = <BadgeDef>[
  // ABC badges
  BadgeDef(id: 'abc_first',    emoji: '🔤', name: 'First Letter!',   desc: 'Open your first letter'),
  BadgeDef(id: 'abc_half',     emoji: '📖', name: 'Half Alphabet',   desc: 'Learn 13 letters'),
  BadgeDef(id: 'abc_all',      emoji: '🎓', name: 'Alphabet Master', desc: 'Learn all 26 letters'),
  BadgeDef(id: 'abc_quiz5',    emoji: '🧠', name: 'Quiz Starter',    desc: 'Score 5/10 on ABC quiz'),
  BadgeDef(id: 'abc_quiz10',   emoji: '💯', name: 'Perfect ABC!',    desc: 'Score 10/10 on ABC quiz'),
  // Math badges
  BadgeDef(id: 'math_first',   emoji: '🔢', name: 'Math Begins!',   desc: 'Complete your first math quiz'),
  BadgeDef(id: 'math_perfect', emoji: '🎯', name: 'Sharpshooter',   desc: 'Score 100% on a math quiz'),
  BadgeDef(id: 'math_blitz10', emoji: '⚡', name: 'Blitz Starter',  desc: 'Score 10 in Blitz mode'),
  BadgeDef(id: 'math_blitz25', emoji: '🏆', name: 'Blitz Champion', desc: 'Score 25 in Blitz mode'),
  BadgeDef(id: 'math_streak5', emoji: '🔥', name: 'Streak Master',  desc: 'Get a 5-answer streak'),
  // Stories badges
  BadgeDef(id: 'story_first',  emoji: '📚', name: 'Story Lover',    desc: 'Finish your first story'),
  BadgeDef(id: 'story_half',   emoji: '🌟', name: 'Bookworm',       desc: 'Finish 4 stories'),
  BadgeDef(id: 'story_all',    emoji: '👑', name: 'Grand Reader',   desc: 'Finish all 8 stories'),
  BadgeDef(id: 'story_hindi',  emoji: '🇮🇳', name: 'Hindi Hero',    desc: 'Finish a story in Hindi'),
  // Daily challenge badges
  BadgeDef(id: 'daily_done',    emoji: '⚡', name: 'Daily Hero',    desc: 'Complete your first Daily Challenge'),
  BadgeDef(id: 'daily_streak3', emoji: '🔥', name: '3-Day Streak',  desc: 'Complete Daily Challenge 3 days in a row'),
  BadgeDef(id: 'daily_streak7', emoji: '🌟', name: 'Week Warrior',  desc: 'Complete Daily Challenge 7 days in a row'),
  // Memory game badges
  BadgeDef(id: 'memory_first', emoji: '🃏', name: 'Card Shark',     desc: 'Win your first Memory Match'),
  BadgeDef(id: 'memory_hard',  emoji: '🧩', name: 'Memory Master',  desc: 'Win Memory Match on Hard'),
  // Nursery Rhyme badges
  BadgeDef(id: 'rhyme_first', emoji: '🎵', name: 'Sing Along!',    desc: 'Play your first nursery rhyme'),
  BadgeDef(id: 'rhyme_all',   emoji: '🎶', name: 'Rhyme Master',   desc: 'Play all 5 nursery rhymes'),
  // Puzzle badges
  BadgeDef(id: 'puzzle_first', emoji: '🧩', name: 'Puzzler!',      desc: 'Solve your first sliding puzzle'),
  BadgeDef(id: 'puzzle_fast',  emoji: '⚡', name: 'Speed Solver',  desc: 'Solve a puzzle in 35 moves or less'),
  // Coloring Book badges
  BadgeDef(id: 'color_first',  emoji: '🎨', name: 'Colorist!',      desc: 'Color your first region'),
  BadgeDef(id: 'color_scene',  emoji: '🖼️', name: 'Masterpiece',    desc: 'Complete a full coloring scene'),
  // Word Builder badges
  BadgeDef(id: 'word_first',   emoji: '🔡', name: 'Word Maker',     desc: 'Spell your first word'),
  BadgeDef(id: 'word_5',       emoji: '📝', name: 'Word Wizard',    desc: 'Spell 5 words in a session'),
  BadgeDef(id: 'word_10',      emoji: '✍️', name: 'Spelling Champ', desc: 'Spell all 10 words correctly'),
  // Counting badges
  BadgeDef(id: 'count_first',  emoji: '🔢', name: 'Counter!',       desc: 'Answer your first counting question'),
  BadgeDef(id: 'count_perfect',emoji: '🏅', name: 'Perfect Count',  desc: 'Score 10/10 in Counting Fun'),
  // Simon Says badges
  BadgeDef(id: 'simon_first', emoji: '🎯', name: 'Pattern Starter', desc: 'Complete your first Simon Says round'),
  BadgeDef(id: 'simon_hard',  emoji: '🧠', name: 'Sequence Master', desc: 'Reach the target round on Hard'),
  // Bubble Pop badges
  BadgeDef(id: 'bubble_first', emoji: '🫧', name: 'Bubble Buster', desc: 'Finish your first Bubble Pop round'),
  BadgeDef(id: 'bubble_ace',   emoji: '💧', name: 'Pop Champion',  desc: 'Score 45+ bubbles in one round'),
  // Shape Sorter badges
  BadgeDef(id: 'shape_first', emoji: '🧸', name: 'Shape Sorter!', desc: 'Sort all shapes for the first time'),
  BadgeDef(id: 'shape_hard',  emoji: '🔷', name: 'Shape Master',  desc: 'Sort all shapes on Hard'),
  // Animal Sound Quiz badges
  BadgeDef(id: 'animal_first',   emoji: '🐾', name: 'Animal Friend', desc: 'Finish your first Animal Sound Quiz'),
  BadgeDef(id: 'animal_perfect', emoji: '🐮', name: 'Animal Expert', desc: 'Score 10/10 on Animal Sound Quiz'),
  // Whack-a-Mole badges
  BadgeDef(id: 'whack_first', emoji: '🔨', name: 'Mole Whacker', desc: 'Finish your first Whack-a-Mole round'),
  BadgeDef(id: 'whack_ace',   emoji: '⚡', name: 'Quick Hands',  desc: 'Score 20+ in one Whack-a-Mole round'),
  // Maze Runner badges
  BadgeDef(id: 'maze_first',    emoji: '🗺️', name: 'Maze Explorer',   desc: 'Solve your first maze'),
  BadgeDef(id: 'maze_all',      emoji: '🏰', name: 'Maze Champion',   desc: 'Solve all 6 mazes'),
  BadgeDef(id: 'maze_endless5', emoji: '🌀', name: 'Endless Wanderer', desc: 'Reach level 5 in Endless Mode'),
  // Animal Feeding badges
  BadgeDef(id: 'feed_first', emoji: '🦖', name: "Animal Friend's Helper", desc: 'Finish your first Animal Feeding round'),
  BadgeDef(id: 'feed_ace',   emoji: '🍖', name: 'Feeding Frenzy',         desc: 'Score 10/10 on Hard'),
  // Archery badges
  BadgeDef(id: 'archery_first',   emoji: '🏹', name: 'First Shot', desc: 'Finish your first Archery round'),
  BadgeDef(id: 'archery_perfect', emoji: '🎯', name: 'Bullseye!',  desc: 'Score 10/10 on Archery'),
  // Racing badges
  BadgeDef(id: 'race_first', emoji: '🏁', name: 'Racing Rookie',  desc: 'Finish your first Racing round'),
  BadgeDef(id: 'race_ace',   emoji: '🏆', name: 'Speed Champion', desc: 'Finish a Hard round with no misses'),
  // Explorer badges
  BadgeDef(id: 'all_apps',     emoji: '🚀', name: 'Explorer',       desc: 'Use ABC, Math and Stories'),
  BadgeDef(id: 'super_star',   emoji: '🌈', name: 'Super Star',     desc: 'Earn 10 badges'),
];

class BadgeService {
  static final BadgeService _i = BadgeService._();
  factory BadgeService() => _i;
  BadgeService._();

  static const _key = 'earned_badges';
  Set<String> _earned = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    _earned = Set.of(p.getStringList(_key) ?? []);
    _loaded = true;
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, _earned.toList());
  }

  Set<String> get earned => Set.unmodifiable(_earned);

  /// Awards the badge if not already earned. Returns true if newly earned.
  Future<bool> award(String id) async {
    await load();
    if (_earned.contains(id)) return false;
    _earned.add(id);
    await _save();
    // Check super_star unlock
    if (_earned.length >= 10 && !_earned.contains('super_star')) {
      _earned.add('super_star');
      await _save();
    }
    return true;
  }

  Future<void> clear() async {
    _earned = {};
    _loaded = true;
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }

  bool has(String id) => _earned.contains(id);
}
