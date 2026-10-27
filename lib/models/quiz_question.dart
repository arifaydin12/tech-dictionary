import '../models/word.dart';

class QuizQuestion {
  final String id;
  final Word word;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;

  QuizQuestion({
    required this.id,
    required this.word,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
  });

  bool isCorrect(int selectedIndex) {
    return selectedIndex == correctAnswerIndex;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'wordId': word.id,
    'options': options,
    'correctAnswerIndex': correctAnswerIndex,
    'explanation': explanation,
  };

  factory QuizQuestion.fromJson(Map<String, dynamic> json, Word word) {
    return QuizQuestion(
      id: json['id'] as String,
      word: word,
      options: List<String>.from(json['options'] as List),
      correctAnswerIndex: json['correctAnswerIndex'] as int,
      explanation: json['explanation'] as String?,
    );
  }
}

class QuizResult {
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final Duration duration;
  final DateTime completedAt;
  final List<QuizQuestion> questions;
  final List<int> userAnswers;

  QuizResult({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.duration,
    required this.completedAt,
    required this.questions,
    required this.userAnswers,
  });

  double get score => (correctAnswers / totalQuestions) * 100;
  double get accuracy => correctAnswers / totalQuestions;

  Map<String, dynamic> toJson() => {
    'totalQuestions': totalQuestions,
    'correctAnswers': correctAnswers,
    'wrongAnswers': wrongAnswers,
    'duration': duration.inSeconds,
    'completedAt': completedAt.toIso8601String(),
    'score': score,
  };
}

