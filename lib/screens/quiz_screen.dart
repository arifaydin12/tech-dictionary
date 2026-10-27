import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/constants.dart';
import '../models/quiz_question.dart';
import '../services/quiz_service.dart';
import '../services/gamification_service.dart';
import '../providers/word_provider.dart';
import '../services/firebase_service.dart';
import 'dart:async';

class QuizScreen extends StatefulWidget {
  final QuizMode mode;
  final int questionCount;

  const QuizScreen({
    super.key,
    required this.mode,
    this.questionCount = 10,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

enum QuizMode {
  multipleChoice,
  trueFalse,
  matching,
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizService _quizService = QuizService();
  final GamificationService _gamificationService = GamificationService();
  final FirebaseService _firebaseService = FirebaseService();
  
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  List<int> _userAnswers = [];
  bool _isAnswered = false;
  DateTime? _startTime;
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _startTime = DateTime.now();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  Future<void> _loadQuestions() async {
    final wordProvider = Provider.of<WordProvider>(context, listen: false);
    final words = wordProvider.words;
    
    if (words.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz için yeterli kelime yok')),
      );
      Navigator.pop(context);
      return;
    }

    setState(() {
      switch (widget.mode) {
        case QuizMode.multipleChoice:
          _questions = _quizService.generateMultipleChoiceQuiz(
            words,
            questionCount: widget.questionCount,
          );
          break;
        case QuizMode.trueFalse:
          _questions = _quizService.generateTrueFalseQuiz(
            words,
            questionCount: widget.questionCount,
          );
          break;
        case QuizMode.matching:
          // Matching için farklı bir ekran gerekir
          _questions = _quizService.generateMultipleChoiceQuiz(
            words,
            questionCount: widget.questionCount,
          );
          break;
      }
      _userAnswers = List.filled(_questions.length, -1);
    });
  }

  void _selectAnswer(int index) {
    if (_isAnswered) return;
    
    setState(() {
      _selectedAnswer = index;
      _isAnswered = true;
      _userAnswers[_currentQuestionIndex] = index;
    });

    // 1 saniye sonra bir sonraki soruya geç
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _isAnswered = false;
      });
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    _timer?.cancel();
    final duration = DateTime.now().difference(_startTime!);
    
    final correctAnswers = _questions.asMap().entries.where((entry) {
      return entry.value.isCorrect(_userAnswers[entry.key]);
    }).length;

    final result = QuizResult(
      totalQuestions: _questions.length,
      correctAnswers: correctAnswers,
      wrongAnswers: _questions.length - correctAnswers,
      duration: duration,
      completedAt: DateTime.now(),
      questions: _questions,
      userAnswers: _userAnswers,
    );

    // Gamification: XP ve rozet kontrolü
    if (_firebaseService.isLoggedIn) {
      await _gamificationService.onQuizCompleted(
        _firebaseService.userId!,
        _quizService.calculateScore(result),
        result.accuracy,
      );
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultScreen(result: result),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Quiz - ${_currentQuestionIndex + 1}/${_questions.length}'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Süre ve ilerleme
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_elapsedSeconds}s',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(_currentQuestionIndex + 1)}/${_questions.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacing32),

            // Soru
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.spacing24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Soru ${_currentQuestionIndex + 1}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing12),
                  Text(
                    question.word.term,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      question.word.category,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacing32),

            // Seçenekler
            Text(
              'Doğru tanımı seçin:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: AppConstants.spacing16),
            
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected = _selectedAnswer == index;
              final isCorrect = index == question.correctAnswerIndex;
              final showResult = _isAnswered;

              Color? backgroundColor;
              Color? borderColor;
              Color? textColor;

              if (showResult) {
                if (isCorrect) {
                  backgroundColor = AppColors.success.withOpacity(0.1);
                  borderColor = AppColors.success;
                  textColor = AppColors.success;
                } else if (isSelected && !isCorrect) {
                  backgroundColor = AppColors.error.withOpacity(0.1);
                  borderColor = AppColors.error;
                  textColor = AppColors.error;
                } else {
                  backgroundColor = Colors.grey[100];
                  borderColor = Colors.grey[300];
                  textColor = AppColors.text;
                }
              } else {
                backgroundColor = isSelected
                    ? AppColors.primaryLight
                    : Theme.of(context).cardColor;
                borderColor = isSelected
                    ? AppColors.primary
                    : AppColors.border;
                textColor = Theme.of(context).textTheme.bodyLarge?.color;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: AppConstants.spacing12),
                child: InkWell(
                  onTap: () => _selectAnswer(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.spacing16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: borderColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index), // A, B, C, D
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: borderColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacing16),
                        Expanded(
                          child: Text(
                            option,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (showResult && isCorrect)
                          Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                          ),
                        if (showResult && isSelected && !isCorrect)
                          Icon(
                            Icons.cancel,
                            color: AppColors.error,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class QuizResultScreen extends StatelessWidget {
  final QuizResult result;

  const QuizResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quiz Sonucu'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacing24),
        child: Column(
          children: [
            // Skor kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.spacing32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: result.score >= 70
                      ? [AppColors.success, AppColors.secondary]
                      : result.score >= 50
                          ? [AppColors.warning, AppColors.accent]
                          : [AppColors.error, Colors.red.shade700],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '${result.score.toInt()}',
                    style: GoogleFonts.poppins(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Puan',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Doğru',
                        '${result.correctAnswers}',
                        Icons.check_circle,
                      ),
                      _buildStatItem(
                        'Yanlış',
                        '${result.wrongAnswers}',
                        Icons.cancel,
                      ),
                      _buildStatItem(
                        'Süre',
                        '${result.duration.inSeconds}s',
                        Icons.timer,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacing32),

            // Detaylı sonuçlar
            ...result.questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              final userAnswer = result.userAnswers[index];
              final isCorrect = question.isCorrect(userAnswer);

              return Container(
                margin: const EdgeInsets.only(bottom: AppConstants.spacing12),
                padding: const EdgeInsets.all(AppConstants.spacing16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCorrect ? AppColors.success : AppColors.error,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Soru ${index + 1}: ${question.word.term}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Seçtiğiniz: ${question.options[userAnswer]}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (question.explanation != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        question.explanation!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            const SizedBox(height: AppConstants.spacing32),

            // Butonlar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tekrar Dene'),
                  ),
                ),
                const SizedBox(width: AppConstants.spacing16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Ana Sayfa'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

