import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/community.dart';
import '../models/word.dart';
import '../repositories/repositories.dart';
import '../utils/dates.dart';

enum RankingPeriod {
  week('This week'),
  allTime('All time');

  const RankingPeriod(this.label);

  final String label;
}

/// A leaderboard row with its position.
class RankedEntry {
  const RankedEntry(this.rank, this.entry, this.xp, {required this.isYou});

  final int rank;
  final RankingEntry entry;
  final int xp;
  final bool isYou;
}

/// Leaderboard and correction suggestions.
class CommunityProvider extends ChangeNotifier {
  CommunityProvider(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final CommunityRepository _repository;
  final DateTime Function() _clock;

  AppUser? _user;
  List<RankingEntry> _rankings = [];
  List<Correction> _incoming = [];
  List<Correction> _sent = [];
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;
  List<Correction> get incoming => _incoming;
  List<Correction> get sent => _sent;

  int get pendingIncoming =>
      _incoming.where((c) => c.status == CorrectionStatus.pending).length;

  Future<void> load(AppUser user) async {
    _user = user;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.fetchRankings(),
        _repository.fetchCorrectionsForOwner(user.id),
        _repository.fetchCorrectionsByProposer(user.id),
      ]);
      _rankings = results[0] as List<RankingEntry>;
      _incoming = results[1] as List<Correction>;
      _sent = results[2] as List<Correction>;
    } on RepositoryException catch (e) {
      _error = e.message;
    } catch (e) {
      debugPrint('Failed to load community data: $e');
      _error = 'Community data could not be loaded.';
    }
    _loading = false;
    notifyListeners();
  }

  void clear() {
    _user = null;
    _rankings = [];
    _incoming = [];
    _sent = [];
    _error = null;
    notifyListeners();
  }

  /// The leaderboard for [period]. The signed-in user's row is built from
  /// [own] so it is always up to date, whatever was published last.
  List<RankedEntry> ranking(RankingPeriod period, RankingEntry? own) {
    final weekStart = Dates.weekStart(_clock());
    final entries = [
      for (final e in _rankings)
        if (own == null || e.userId != own.userId) e,
      ?own,
    ];
    int xpOf(RankingEntry e) =>
        period == RankingPeriod.week ? e.weeklyXpFor(weekStart) : e.totalXp;
    entries.sort((a, b) {
      final c = xpOf(b).compareTo(xpOf(a));
      return c != 0 ? c : a.displayName.compareTo(b.displayName);
    });
    return [
      for (var i = 0; i < entries.length; i++)
        RankedEntry(
          i + 1,
          entries[i],
          xpOf(entries[i]),
          isYou: own != null && entries[i].userId == own.userId,
        ),
    ];
  }

  /// Suggest a new definition for a community word written by someone else.
  Future<void> suggestCorrection({
    required Word word,
    required String definition,
    String? note,
  }) async {
    final user = _user;
    final ownerId = word.authorId;
    if (user == null || ownerId == null || word.isBuiltIn) {
      throw const RepositoryException(
        'Corrections can only be suggested for community terms.',
      );
    }
    if (word.isOwnedBy(user.id)) {
      throw const RepositoryException('You can edit your own terms directly.');
    }
    if (definition.trim().length < 10) {
      throw const RepositoryException(
        'The suggested definition must be at least 10 characters.',
      );
    }
    final trimmedNote = note?.trim();
    await _repository.submitCorrection(
      Correction(
        id: '',
        wordId: word.id,
        wordTerm: word.term,
        ownerId: ownerId,
        proposerId: user.id,
        proposerName: user.displayName,
        proposedDefinition: definition.trim(),
        note: (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
        createdAt: _clock(),
      ),
    );
    await load(user);
  }

  /// Accepts or rejects a suggestion for one of the user's own words. The
  /// caller applies an accepted definition to the word.
  Future<void> resolve(Correction correction, CorrectionStatus status) async {
    await _repository.resolveCorrection(correction.id, status);
    _incoming = [
      for (final c in _incoming)
        c.id == correction.id ? c.copyWith(status: status) : c,
    ];
    notifyListeners();
  }
}
