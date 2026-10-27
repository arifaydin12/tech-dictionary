import 'dart:math';
import '../models/word.dart';
import '../models/quiz_question.dart';

class QuizService {
  static const int defaultQuestionCount = 10;

  /// Çoktan seçmeli quiz soruları oluştur
  List<QuizQuestion> generateMultipleChoiceQuiz(
    List<Word> words, {
    int questionCount = defaultQuestionCount,
  }) {
    if (words.length < 4) {
      throw Exception('En az 4 kelime gerekli');
    }

    final random = Random();
    final selectedWords = List<Word>.from(words);
    selectedWords.shuffle(random);
    final questions = selectedWords.take(questionCount).toList();

    return questions.map((word) {
      // Doğru cevap
      final correctAnswer = word.definition;
      
      // Yanlış cevaplar (diğer kelimelerden)
      final wrongAnswers = <String>[];
      final otherWords = words.where((w) => w.id != word.id).toList();
      otherWords.shuffle(random);
      
      for (var i = 0; i < 3 && i < otherWords.length; i++) {
        wrongAnswers.add(otherWords[i].definition);
      }
      
      // Eğer yeterli yanlış cevap yoksa, rastgele metinler ekle
      while (wrongAnswers.length < 3) {
        wrongAnswers.add('Bu terim için geçerli bir tanım değil.');
      }
      
      // Tüm seçenekleri birleştir ve karıştır
      final options = [correctAnswer, ...wrongAnswers];
      options.shuffle(random);
      
      // Doğru cevabın index'ini bul
      final correctIndex = options.indexOf(correctAnswer);
      
      return QuizQuestion(
        id: 'quiz_${word.id}_${DateTime.now().millisecondsSinceEpoch}',
        word: word,
        options: options,
        correctAnswerIndex: correctIndex,
        explanation: 'Doğru cevap: ${word.term}',
      );
    }).toList();
  }

  /// Doğru/Yanlış quiz soruları oluştur
  List<QuizQuestion> generateTrueFalseQuiz(
    List<Word> words, {
    int questionCount = defaultQuestionCount,
  }) {
    final random = Random();
    final selectedWords = List<Word>.from(words);
    selectedWords.shuffle(random);
    final questions = selectedWords.take(questionCount).toList();

    return questions.map((word) {
      // %70 ihtimalle doğru, %30 ihtimalle yanlış tanım
      final isTrue = random.nextDouble() > 0.3;
      
      String definition;
      int correctIndex;
      
      if (isTrue) {
        definition = word.definition;
        correctIndex = 0; // Doğru
      } else {
        // Yanlış tanım oluştur
        final otherWords = words.where((w) => w.id != word.id).toList();
        if (otherWords.isNotEmpty) {
          definition = otherWords[random.nextInt(otherWords.length)].definition;
        } else {
          definition = 'Bu terim için geçerli bir tanım değil.';
        }
        correctIndex = 1; // Yanlış
      }
      
      return QuizQuestion(
        id: 'quiz_tf_${word.id}_${DateTime.now().millisecondsSinceEpoch}',
        word: word,
        options: ['Doğru', 'Yanlış'],
        correctAnswerIndex: correctIndex,
        explanation: isTrue 
            ? 'Doğru! ${word.term}: ${word.definition}'
            : 'Yanlış! Doğrusu: ${word.term}: ${word.definition}',
      );
    }).toList();
  }

  /// Kelime eşleştirme quiz'i oluştur
  List<Map<String, dynamic>> generateMatchingQuiz(
    List<Word> words, {
    int pairCount = 5,
  }) {
    final random = Random();
    final selectedWords = List<Word>.from(words);
    selectedWords.shuffle(random);
    final pairs = selectedWords.take(pairCount).toList();

    final terms = pairs.map((w) => w.term).toList();
    final definitions = pairs.map((w) => w.definition).toList();
    definitions.shuffle(random);

    return pairs.map((word) {
      return {
        'term': word.term,
        'definition': word.definition,
        'options': definitions,
        'correctIndex': definitions.indexOf(word.definition),
      };
    }).toList();
  }

  /// Quiz puanını hesapla
  int calculateScore(QuizResult result) {
    final baseScore = result.correctAnswers * 10;
    final timeBonus = (result.duration.inSeconds < 60) ? 50 : 0;
    final accuracyBonus = (result.accuracy >= 0.8) ? 30 : 0;
    
    return baseScore + timeBonus + accuracyBonus;
  }
}

