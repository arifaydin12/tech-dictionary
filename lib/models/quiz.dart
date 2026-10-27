import 'word.dart';

/// The three ways a word can be practised.
enum QuizMode {
  multipleChoice('Multiple choice', 'Pick the right term for a definition.'),
  flashcards('Flashcards', 'Flip cards and rate how well you knew them.'),
  typing('Typing', 'Type the term that matches the definition.');

  const QuizMode(this.label, this.description);

  final String label;
  final String description;

  static QuizMode fromName(String? name) => QuizMode.values.firstWhere(
    (m) => m.name == name,
    orElse: () => QuizMode.multipleChoice,
  );
}

/// One question in a practice session.
class QuizQuestion {
  const QuizQuestion({
    required this.word,
    required this.mode,
    this.options = const [],
  });

  final Word word;
  final QuizMode mode;

  /// Answer options (terms) for [QuizMode.multipleChoice]; empty otherwise.
  /// Always contains [Word.term] exactly once.
  final List<String> options;
}

/// How a typed answer compares with the expected term.
enum AnswerMatch { exact, close, wrong }

/// Persisted summary of a finished practice session.
class QuizResult {
  const QuizResult({
    required this.date,
    required this.mode,
    required this.total,
    required this.correct,
    this.category,
  });

  final DateTime date;
  final QuizMode mode;
  final int total;
  final int correct;
  final String? category;

  double get accuracy => total == 0 ? 0 : correct / total;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'mode': mode.name,
    'total': total,
    'correct': correct,
    'category': category,
  };

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
    date: DateTime.parse(json['date'] as String),
    mode: QuizMode.fromName(json['mode'] as String?),
    total: (json['total'] as num).toInt(),
    correct: (json['correct'] as num).toInt(),
    category: json['category'] as String?,
  );
}
