class QuizQuestion {
  final String answer;
  final String emoji;
  final String word;
  final List<String> choices;

  const QuizQuestion({
    required this.answer,
    required this.emoji,
    required this.word,
    required this.choices,
  });
}
