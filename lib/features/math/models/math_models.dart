enum MathView { modeSelect, settings, quiz, blitz, result }
enum MathMode { practice, tables, blitz }
enum MathOp { add, sub, mul }
enum Difficulty { easy, med, hard }

class MathQuestion {
  final String display;
  final int answer;
  final List<int> choices;

  const MathQuestion({
    required this.display,
    required this.answer,
    required this.choices,
  });
}

class MathLeaderboardEntry {
  final String name;
  final int score;
  final int total;

  const MathLeaderboardEntry({
    required this.name,
    required this.score,
    required this.total,
  });
}
