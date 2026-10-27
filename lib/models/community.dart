/// One row of the leaderboard.
class RankingEntry {
  const RankingEntry({
    required this.userId,
    required this.displayName,
    required this.totalXp,
    required this.weeklyXp,
    required this.streak,
    required this.wordsAdded,
    this.weekStart,
  });

  final String userId;
  final String displayName;
  final int totalXp;

  /// XP earned in the week starting at [weekStart].
  final int weeklyXp;
  final int streak;
  final int wordsAdded;
  final DateTime? weekStart;

  /// Weekly XP, or 0 if the entry was last published in an earlier week.
  int weeklyXpFor(DateTime currentWeekStart) {
    final w = weekStart;
    if (w == null) return weeklyXp;
    final same =
        w.year == currentWeekStart.year &&
        w.month == currentWeekStart.month &&
        w.day == currentWeekStart.day;
    return same ? weeklyXp : 0;
  }

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'totalXp': totalXp,
    'weeklyXp': weeklyXp,
    'streak': streak,
    'wordsAdded': wordsAdded,
    'weekStart': weekStart?.toIso8601String(),
  };

  factory RankingEntry.fromJson(Map<String, dynamic> json, String userId) {
    final week = json['weekStart'];
    return RankingEntry(
      userId: userId,
      displayName: (json['displayName'] as String?) ?? 'Anonymous',
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      weeklyXp: (json['weeklyXp'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      wordsAdded: (json['wordsAdded'] as num?)?.toInt() ?? 0,
      weekStart: week is String ? DateTime.tryParse(week) : null,
    );
  }
}

enum CorrectionStatus { pending, accepted, rejected }

/// A proposed edit to the definition of a community word.
class Correction {
  const Correction({
    required this.id,
    required this.wordId,
    required this.wordTerm,
    required this.ownerId,
    required this.proposerId,
    required this.proposerName,
    required this.proposedDefinition,
    required this.createdAt,
    this.note,
    this.status = CorrectionStatus.pending,
  });

  final String id;
  final String wordId;
  final String wordTerm;

  /// Author of the word, who reviews the suggestion.
  final String ownerId;
  final String proposerId;
  final String proposerName;
  final String proposedDefinition;
  final String? note;
  final DateTime createdAt;
  final CorrectionStatus status;

  Correction copyWith({CorrectionStatus? status}) => Correction(
    id: id,
    wordId: wordId,
    wordTerm: wordTerm,
    ownerId: ownerId,
    proposerId: proposerId,
    proposerName: proposerName,
    proposedDefinition: proposedDefinition,
    createdAt: createdAt,
    note: note,
    status: status ?? this.status,
  );

  Map<String, dynamic> toJson() => {
    'wordId': wordId,
    'wordTerm': wordTerm,
    'ownerId': ownerId,
    'proposerId': proposerId,
    'proposerName': proposerName,
    'proposedDefinition': proposedDefinition,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
  };

  factory Correction.fromJson(Map<String, dynamic> json, String id) {
    return Correction(
      id: id,
      wordId: json['wordId'] as String,
      wordTerm: json['wordTerm'] as String,
      ownerId: json['ownerId'] as String,
      proposerId: json['proposerId'] as String,
      proposerName: (json['proposerName'] as String?) ?? 'Anonymous',
      proposedDefinition: json['proposedDefinition'] as String,
      note: json['note'] as String?,
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      status: CorrectionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => CorrectionStatus.pending,
      ),
    );
  }
}
