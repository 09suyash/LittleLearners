import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

enum ChallengeType { math, letter, trivia }

class DailyChallenge {
  final ChallengeType type;
  final String question;
  final String answer;        // correct answer string
  final List<String> choices; // 4 shuffled choices
  final String emoji;
  const DailyChallenge({
    required this.type,
    required this.question,
    required this.answer,
    required this.choices,
    required this.emoji,
  });
}

class DailyChallengeService {
  static final DailyChallengeService _i = DailyChallengeService._();
  factory DailyChallengeService() => _i;
  DailyChallengeService._();

  static const _keyDate    = 'dc_date';
  static const _keyDone    = 'dc_done';
  static const _keyStreak  = 'dc_streak';
  static const _keyLastStr = 'dc_last_streak_date';

  // Returns today as YYYY-MM-DD string
  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<bool> isCompletedToday() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyDate) == _today() && (p.getBool(_keyDone) ?? false);
  }

  Future<int> getStreak() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_keyStreak) ?? 0;
  }

  Future<void> markCompleted() async {
    final p = await SharedPreferences.getInstance();
    final today = _today();
    final lastStreakDate = p.getString(_keyLastStr) ?? '';
    final streak = p.getInt(_keyStreak) ?? 0;

    // Calculate yesterday string
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    final newStreak = (lastStreakDate == yStr || lastStreakDate == today)
        ? (lastStreakDate == today ? streak : streak + 1)
        : 1;

    await p.setString(_keyDate, today);
    await p.setBool(_keyDone, true);
    await p.setInt(_keyStreak, newStreak);
    await p.setString(_keyLastStr, today);
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_keyDate);
    await p.remove(_keyDone);
    await p.remove(_keyStreak);
    await p.remove(_keyLastStr);
  }

  /// Generates today's challenge deterministically from the date seed.
  DailyChallenge generateChallenge() {
    final today = _today();
    final seed = today.hashCode.abs();
    final rng = Random(seed);

    final typeIdx = rng.nextInt(3);
    final type = ChallengeType.values[typeIdx];

    switch (type) {
      case ChallengeType.math:
        return _mathChallenge(rng);
      case ChallengeType.letter:
        return _letterChallenge(rng);
      case ChallengeType.trivia:
        return _triviaChallenge(rng);
    }
  }

  DailyChallenge _mathChallenge(Random rng) {
    final ops = ['+', '-', '×'];
    final op = ops[rng.nextInt(3)];
    int a, b, ans;
    String question;
    if (op == '+') {
      a = rng.nextInt(15) + 1; b = rng.nextInt(15) + 1; ans = a + b;
      question = 'What is $a + $b?';
    } else if (op == '-') {
      a = rng.nextInt(18) + 3; b = rng.nextInt(a - 1) + 1; ans = a - b;
      question = 'What is $a − $b?';
    } else {
      a = rng.nextInt(9) + 2; b = rng.nextInt(9) + 2; ans = a * b;
      question = 'What is $a × $b?';
    }
    final choices = _intChoices(rng, ans);
    return DailyChallenge(type: ChallengeType.math, question: question,
        answer: '$ans', choices: choices, emoji: '🔢');
  }

  DailyChallenge _letterChallenge(Random rng) {
    const pairs = [
      ('A', 'Apple', '🍎'), ('B', 'Balloon', '🎈'), ('C', 'Cat', '🐱'),
      ('D', 'Dog', '🐶'),   ('E', 'Egg', '🥚'),     ('F', 'Fish', '🐟'),
      ('G', 'Grapes', '🍇'),('H', 'Hat', '🎩'),     ('I', 'Iguana', '🦎'),
      ('J', 'Juice', '🧃'), ('K', 'Kite', '🪁'),    ('L', 'Lion', '🦁'),
      ('M', 'Mango', '🥭'), ('N', 'Nest', '🪺'),    ('O', 'Orange', '🍊'),
      ('P', 'Parrot', '🦜'),('Q', 'Queen', '👑'),   ('R', 'Rainbow', '🌈'),
      ('S', 'Sun', '☀️'),   ('T', 'Tiger', '🐯'),   ('U', 'Umbrella', '☂️'),
      ('V', 'Van', '🚐'),   ('W', 'Whale', '🐋'),   ('X', 'X-ray', '🩻'),
      ('Y', 'Yak', '🐂'),   ('Z', 'Zebra', '🦓'),
    ];
    final pick = pairs[rng.nextInt(pairs.length)];
    final allLetters = pairs.map((p) => p.$1).toList();
    allLetters.remove(pick.$1);
    allLetters.shuffle(rng);
    final choices = ([pick.$1, ...allLetters.take(3)])..shuffle(rng);
    return DailyChallenge(
      type: ChallengeType.letter,
      question: '${pick.$3}  What letter does "${pick.$2}" start with?',
      answer: pick.$1,
      choices: choices.map((c) => c).toList(),
      emoji: '🔤',
    );
  }

  DailyChallenge _triviaChallenge(Random rng) {
    const questions = [
      ('Which animal says Moo? 🐄', 'Cow',      ['Cow', 'Dog', 'Cat', 'Horse']),
      ('How many legs does a spider have? 🕷️', '8', ['8', '6', '4', '10']),
      ('What color is the sky? ☁️', 'Blue',      ['Blue', 'Red', 'Green', 'Yellow']),
      ('Which fruit is yellow and curved? 🍌', 'Banana', ['Banana', 'Apple', 'Mango', 'Grape']),
      ('How many days in a week? 📅', '7',       ['7', '5', '6', '8']),
      ('What sound does a lion make? 🦁', 'Roar', ['Roar', 'Moo', 'Bark', 'Meow']),
      ('Which planet do we live on? 🌍', 'Earth', ['Earth', 'Mars', 'Moon', 'Sun']),
      ('How many fingers on one hand? ✋', '5',   ['5', '4', '6', '10']),
      ('What do caterpillars turn into? 🦋', 'Butterfly', ['Butterfly', 'Bee', 'Dragonfly', 'Moth']),
      ('Which animal gives us milk? 🥛', 'Cow',  ['Cow', 'Hen', 'Fish', 'Dog']),
      ('What is 2 + 2? 🔢', '4',                 ['4', '3', '5', '6']),
      ('Which shape has 3 sides? 🔺', 'Triangle', ['Triangle', 'Square', 'Circle', 'Rectangle']),
      ('What do bees make? 🍯', 'Honey',         ['Honey', 'Milk', 'Juice', 'Butter']),
      ('Which month comes after January? 📆', 'February', ['February', 'March', 'April', 'December']),
      ('How many months in a year? 🗓️', '12',    ['12', '10', '11', '365']),
    ];
    final q = questions[rng.nextInt(questions.length)];
    final choices = List<String>.from(q.$3)..shuffle(rng);
    return DailyChallenge(type: ChallengeType.trivia,
        question: q.$1, answer: q.$2, choices: choices, emoji: '🌟');
  }

  List<String> _intChoices(Random rng, int ans) {
    final s = <int>{ans};
    int t = 0;
    while (s.length < 4 && t < 60) {
      final d = rng.nextInt(6) + 1;
      final c = ans + (rng.nextBool() ? d : -d);
      if (c >= 0) s.add(c);
      t++;
    }
    for (int x = 1; s.length < 4; x++) { s.add(ans + x); }
    return (s.toList()..shuffle(rng)).map((n) => '$n').toList();
  }
}
