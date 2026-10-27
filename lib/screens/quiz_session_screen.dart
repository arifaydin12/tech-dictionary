import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card_state.dart';
import '../models/quiz.dart';
import '../models/word.dart';
import '../providers/dictionary_provider.dart';
import '../providers/progress_provider.dart';
import '../services/gamification_service.dart';
import '../services/quiz_service.dart';
import '../services/spaced_repetition.dart';
import '../ui/widgets.dart';
import 'dictionary_tab.dart';

/// A practice session in one of the three quiz modes.
class QuizSessionScreen extends StatefulWidget {
  const QuizSessionScreen({
    super.key,
    required this.mode,
    required this.questionCount,
    this.category,
  });

  final QuizMode mode;
  final int questionCount;
  final String? category;

  @override
  State<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen> {
  late final QuizService _quiz;
  late final ProgressProvider _progress;
  late final List<QuizQuestion> _questions;

  final _typed = TextEditingController();
  final _typedFocus = FocusNode();

  int _index = 0;
  int _correct = 0;
  int _answers = 0;
  final List<Word> _missed = [];

  // Per-question state.
  bool _answered = false;
  String? _selected;
  AnswerMatch? _match;
  bool _flipped = false;

  SessionSummary? _summary;
  bool _finishing = false;

  QuizQuestion get _question => _questions[_index];
  bool get _inProgress => _summary == null && _answers > 0;

  @override
  void initState() {
    super.initState();
    _quiz = context.read<QuizService>();
    _progress = context.read<ProgressProvider>();
    final dictionary = context.read<DictionaryProvider>();
    final selected = _quiz.selectWords(
      words: dictionary.all,
      cards: _progress.progress.cards,
      count: widget.questionCount,
      now: _progress.now,
      category: widget.category,
    );
    _questions = _quiz.buildQuestions(
      selected: selected,
      allWords: dictionary.all,
      mode: widget.mode,
    );
    _progress.beginSession();
  }

  @override
  void dispose() {
    _typed.dispose();
    _typedFocus.dispose();
    super.dispose();
  }

  void _record(AnswerOutcome outcome) {
    _progress.recordAnswer(_question.word, outcome);
    _answers++;
    if (outcome.correct) {
      _correct++;
    } else {
      _missed.add(_question.word);
    }
  }

  void _chooseOption(String option) {
    if (_answered) return;
    final isCorrect = option == _question.word.term;
    setState(() {
      _selected = option;
      _answered = true;
      _record(_quiz.multipleChoice(isCorrect: isCorrect));
    });
  }

  void _checkTyped() {
    if (_answered) return;
    final match = _quiz.checkTyped(_typed.text, _question.word.term);
    setState(() {
      _match = match;
      _answered = true;
      _record(_quiz.typed(match));
    });
  }

  void _grade(FlashcardGrade grade) {
    setState(() => _record(_quiz.flashcard(grade)));
    _advance();
  }

  Future<void> _advance() async {
    if (_index + 1 >= _questions.length) {
      await _finish();
      return;
    }
    setState(() {
      _index++;
      _answered = false;
      _selected = null;
      _match = null;
      _flipped = false;
      _typed.clear();
    });
    if (widget.mode == QuizMode.typing) _typedFocus.requestFocus();
  }

  Future<void> _finish() async {
    setState(() => _finishing = true);
    final summary = await _progress.finishSession(
      mode: widget.mode,
      total: _questions.length,
      correct: _correct,
      bonusXp: _quiz.sessionBonus(total: _questions.length, correct: _correct),
      category: widget.category,
    );
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _finishing = false;
    });
  }

  Future<void> _confirmLeave() async {
    final navigator = Navigator.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this session?'),
        content: const Text('The answers you have given so far are kept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep practising'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true) {
      await _progress.flush();
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.mode.label)),
        body: const EmptyState(
          icon: Icons.inbox_outlined,
          title: 'Nothing to practise',
          message: 'There are no terms in this category yet.',
        ),
      );
    }

    return PopScope(
      canPop: !_inProgress,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.mode.label),
          leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: _inProgress
                ? _confirmLeave
                : () => Navigator.of(context).pop(),
          ),
          bottom: _summary == null
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(4),
                  child: Semantics(
                    label: 'Question ${_index + 1} of ${_questions.length}',
                    child: LinearProgressIndicator(
                      value: (_index + (_answered ? 1 : 0)) / _questions.length,
                      minHeight: 4,
                    ),
                  ),
                )
              : null,
        ),
        body: _summary != null
            ? _ResultView(
                summary: _summary!,
                missed: _missed,
                mode: widget.mode,
                onAgain: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => QuizSessionScreen(
                      mode: widget.mode,
                      questionCount: widget.questionCount,
                      category: widget.category,
                    ),
                  ),
                ),
                onDone: () => Navigator.of(context).pop(),
              )
            : SingleChildScrollView(
                child: ContentWidth(
                  maxWidth: 680,
                  child: Padding(
                    padding: pagePadding(context),
                    child: _questionView(),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _questionView() {
    final theme = Theme.of(context);
    final isLast = _index + 1 >= _questions.length;
    return Column(
      key: ValueKey('question-$_index'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Question ${_index + 1} of ${_questions.length}',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        switch (widget.mode) {
          QuizMode.multipleChoice => _multipleChoice(isLast),
          QuizMode.typing => _typing(isLast),
          QuizMode.flashcards => _flashcard(),
        },
      ],
    );
  }

  Widget _definitionCard(String prompt) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              prompt,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _question.word.definition,
              style: theme.textTheme.titleMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 10),
            CategoryLabel(category: _question.word.category),
          ],
        ),
      ),
    );
  }

  Widget _nextButton(bool isLast) {
    return FilledButton.icon(
      onPressed: _finishing ? null : _advance,
      icon: Icon(isLast ? Icons.flag : Icons.arrow_forward),
      label: Text(isLast ? 'Finish' : 'Next'),
    );
  }

  // ------------------------------------------------------ multiple choice

  Widget _multipleChoice(bool isLast) {
    final correctTerm = _question.word.term;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _definitionCard('Which term matches this definition?'),
        const SizedBox(height: 16),
        for (final (i, option) in _question.options.indexed) ...[
          _OptionTile(
            key: ValueKey('option-$i'),
            label: option,
            state: !_answered
                ? _OptionState.idle
                : option == correctTerm
                ? _OptionState.correct
                : option == _selected
                ? _OptionState.wrong
                : _OptionState.dimmed,
            onTap: () => _chooseOption(option),
          ),
          const SizedBox(height: 10),
        ],
        if (_answered) ...[
          const SizedBox(height: 6),
          _Feedback(
            correct: _selected == correctTerm,
            message: _selected == correctTerm
                ? 'Correct!'
                : 'Not quite. The answer is $correctTerm.',
          ),
          const SizedBox(height: 12),
          _nextButton(isLast),
        ],
      ],
    );
  }

  // --------------------------------------------------------------- typing

  Widget _typing(bool isLast) {
    final term = _question.word.term;
    final match = _match;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _definitionCard('Type the term that matches this definition'),
        const SizedBox(height: 16),
        TextField(
          controller: _typed,
          focusNode: _typedFocus,
          autofocus: true,
          readOnly: _answered,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _answered ? _advance() : _checkTyped(),
          decoration: const InputDecoration(
            labelText: 'Your answer',
            hintText: 'Type the term',
          ),
        ),
        const SizedBox(height: 12),
        if (!_answered)
          FilledButton(onPressed: _checkTyped, child: const Text('Check'))
        else ...[
          _Feedback(
            correct: match != AnswerMatch.wrong,
            message: switch (match) {
              AnswerMatch.exact => 'Correct!',
              AnswerMatch.close => 'Almost: the exact term is $term.',
              _ => 'Not quite. The answer is $term.',
            },
          ),
          const SizedBox(height: 12),
          _nextButton(isLast),
        ],
      ],
    );
  }

  // ------------------------------------------------------------ flashcard

  Widget _flashcard() {
    final theme = Theme.of(context);
    final word = _question.word;
    final card = _progress.cardFor(word.id) ?? CardState(wordId: word.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: _flipped
              ? 'Flashcard answer: ${word.definition}'
              : 'Flashcard: ${word.term}. Double tap to show the definition.',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => setState(() => _flipped = true),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Card(
                key: ValueKey(_flipped),
                color: _flipped
                    ? theme.colorScheme.secondaryContainer
                    : theme.colorScheme.primaryContainer,
                child: SizedBox(
                  height: 260,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: SingleChildScrollView(
                        child: _flipped
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    word.term,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    word.definition,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CategoryLabel(
                                    category: word.category,
                                    dense: false,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    word.term,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.displaySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 36,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tap to reveal the definition',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!_flipped)
          FilledButton.icon(
            onPressed: () => setState(() => _flipped = true),
            icon: const Icon(Icons.flip),
            label: const Text('Show answer'),
          )
        else ...[
          Text(
            'How well did you know it?',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final grade in FlashcardGrade.values)
                _GradeButton(
                  grade: grade,
                  nextInterval: SpacedRepetition.review(
                    card,
                    grade.quality,
                    _progress.now,
                  ).intervalDays,
                  onPressed: () => _grade(grade),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const green = Color(0xFF2B8A3E);
    Color? background;
    Color border = scheme.outlineVariant;
    IconData? icon;
    Color? iconColor;
    switch (state) {
      case _OptionState.correct:
        background = green.withValues(alpha: 0.14);
        border = green;
        icon = Icons.check_circle;
        iconColor = green;
      case _OptionState.wrong:
        background = scheme.error.withValues(alpha: 0.12);
        border = scheme.error;
        icon = Icons.cancel;
        iconColor = scheme.error;
      case _OptionState.dimmed:
      case _OptionState.idle:
        break;
    }
    return Opacity(
      opacity: state == _OptionState.dimmed ? 0.55 : 1,
      child: Material(
        color: background ?? scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: icon == null ? 1 : 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: state == _OptionState.idle ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (icon != null) Icon(icon, color: iconColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.correct, required this.message});

  final bool correct;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const green = Color(0xFF2B8A3E);
    final color = correct ? green : scheme.error;
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Icon(correct ? Icons.check_circle : Icons.info, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({
    required this.grade,
    required this.nextInterval,
    required this.onPressed,
  });

  final FlashcardGrade grade;
  final int nextInterval;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final interval = nextInterval == 1 ? '1 day' : '$nextInterval days';
    return Semantics(
      button: true,
      label: '${grade.label}. Next review in $interval.',
      excludeSemantics: true,
      child: SizedBox(
        width: 140,
        child: grade == FlashcardGrade.again
            ? OutlinedButton(onPressed: onPressed, child: _label(interval))
            : FilledButton.tonal(onPressed: onPressed, child: _label(interval)),
      ),
    );
  }

  Widget _label(String interval) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(grade.label, style: const TextStyle(fontWeight: FontWeight.w700)),
      Text(interval, style: const TextStyle(fontSize: 11)),
    ],
  );
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.summary,
    required this.missed,
    required this.mode,
    required this.onAgain,
    required this.onDone,
  });

  final SessionSummary summary;
  final List<Word> missed;
  final QuizMode mode;
  final VoidCallback onAgain;
  final VoidCallback onDone;

  String get _headline {
    final a = summary.accuracy;
    if (a == 1) return 'Perfect score!';
    if (a >= 0.8) return 'Great work!';
    if (a >= 0.5) return 'Good effort!';
    return 'Keep practising!';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (summary.accuracy * 100).round();
    return SingleChildScrollView(
      child: ContentWidth(
        maxWidth: 680,
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Semantics(
                    container: true,
                    label:
                        '$_headline ${summary.correct} of ${summary.total} correct, '
                        '${summary.xpEarned} experience points earned.',
                    child: ExcludeSemantics(
                      child: Column(
                        children: [
                          Text(
                            _headline,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 140,
                            height: 140,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: summary.accuracy,
                                  strokeWidth: 10,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${summary.correct}/${summary.total}',
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      Text('$percent% correct'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              Chip(
                                avatar: const Icon(Icons.bolt, size: 18),
                                label: Text('+${summary.xpEarned} XP'),
                              ),
                              if (summary.bonusXp > 0)
                                Chip(
                                  avatar: const Icon(
                                    Icons.card_giftcard,
                                    size: 18,
                                  ),
                                  label: Text('Bonus +${summary.bonusXp}'),
                                ),
                              if (summary.leveledUpTo != null)
                                Chip(
                                  avatar: const Icon(
                                    Icons.military_tech,
                                    size: 18,
                                  ),
                                  label: Text('Level ${summary.leveledUpTo}!'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (summary.newBadges.isNotEmpty) ...[
                const SizedBox(height: 16),
                _NewBadges(badges: summary.newBadges),
              ],
              if (missed.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Terms to review',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final word in missed)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(word.term),
                      subtitle: Text(
                        word.definition,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => openWord(context, word),
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAgain,
                icon: const Icon(Icons.replay),
                label: const Text('Practise again'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: onDone, child: const Text('Done')),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewBadges extends StatelessWidget {
  const _NewBadges({required this.badges});

  final List<BadgeDef> badges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              badges.length == 1 ? 'Badge unlocked' : 'Badges unlocked',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            for (final b in badges)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(b.icon, color: theme.colorScheme.onTertiaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${b.title}: ${b.description}',
                        style: TextStyle(
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
