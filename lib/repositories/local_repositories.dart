import 'dart:convert';

import '../data/demo_seed.dart';
import '../data/key_value_store.dart';
import '../models/app_user.dart';
import '../models/community.dart';
import '../models/user_progress.dart';
import '../models/word.dart';
import 'repositories.dart';

/// Demo-mode authentication: a single local guest, no network involved.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._store);

  final KeyValueStore _store;

  static const _key = 'local.session';

  @override
  bool get supportsAccounts => false;

  @override
  Future<AppUser?> restoreSession() async {
    if (_store.read(_key) == null) return null;
    return _guest();
  }

  AppUser _guest() => const AppUser(
    id: DemoSeed.guestId,
    displayName: DemoSeed.guestName,
    isGuest: true,
  );

  @override
  Future<AppUser> signInAsGuest() async {
    await _store.write(_key, DemoSeed.guestId);
    return _guest();
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) =>
      throw const RepositoryException(
        'Accounts are not available in demo mode. Continue as a guest.',
      );

  @override
  Future<AppUser> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) => signInWithEmail(email, password);

  @override
  Future<AppUser> signInWithGoogle() => signInWithEmail('', '');

  @override
  Future<void> signOut() => _store.remove(_key);
}

/// Community words kept in the local store, seeded with fictional entries.
class LocalWordRepository implements WordRepository {
  LocalWordRepository(this._store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final KeyValueStore _store;
  final DateTime Function() _clock;

  static const _key = 'local.words';

  List<Word> _read() {
    final raw = _store.read(_key);
    if (raw == null) return DemoSeed.communityWords(_clock());
    final list = jsonDecode(raw) as List<dynamic>;
    return [for (final e in list) Word.fromJson(e as Map<String, dynamic>)];
  }

  Future<void> _write(List<Word> words) =>
      _store.write(_key, jsonEncode([for (final w in words) w.toJson()]));

  @override
  Future<List<Word>> fetchCommunityWords() async => _read();

  @override
  Future<Word> addWord(Word draft, AppUser author) async {
    final words = _read();
    final word = Word(
      id: 'u-${_clock().microsecondsSinceEpoch}',
      term: draft.term,
      definition: draft.definition,
      category: draft.category,
      example: draft.example,
      authorId: author.id,
      authorName: author.displayName,
      createdAt: _clock(),
    );
    await _write([...words, word]);
    return word;
  }

  @override
  Future<void> updateWord(Word word) async {
    final words = _read();
    await _write([for (final w in words) w.id == word.id ? word : w]);
  }

  @override
  Future<void> deleteWord(String wordId) async {
    await _write([
      for (final w in _read())
        if (w.id != wordId) w,
    ]);
  }
}

/// Progress kept in the local store. With [seedDemoHistory] a first-time user
/// starts with a believable learning history.
class LocalProgressRepository implements ProgressRepository {
  LocalProgressRepository(
    this._store, {
    this.seedDemoHistory = false,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final KeyValueStore _store;
  final bool seedDemoHistory;
  final DateTime Function() _clock;

  String _key(String userId) => 'local.progress.$userId';

  @override
  Future<UserProgress> load(String userId) async {
    final raw = _store.read(_key(userId));
    if (raw == null) {
      return seedDemoHistory ? DemoSeed.progress(_clock()) : UserProgress();
    }
    try {
      return UserProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return UserProgress();
    }
  }

  @override
  Future<void> save(String userId, UserProgress progress) =>
      _store.write(_key(userId), jsonEncode(progress.toJson()));
}

/// Leaderboard and corrections kept locally; fictional users fill the board.
class LocalCommunityRepository implements CommunityRepository {
  LocalCommunityRepository(this._store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final KeyValueStore _store;
  final DateTime Function() _clock;

  static const _rankKey = 'local.rankings';
  static const _correctionKey = 'local.corrections';

  Map<String, RankingEntry> _readOwnEntries() {
    final raw = _store.read(_rankKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final e in map.entries)
        e.key: RankingEntry.fromJson(e.value as Map<String, dynamic>, e.key),
    };
  }

  @override
  Future<List<RankingEntry>> fetchRankings() async => [
    ...DemoSeed.rankings,
    ..._readOwnEntries().values,
  ];

  @override
  Future<void> publishRanking(RankingEntry entry) async {
    final own = _readOwnEntries()..[entry.userId] = entry;
    await _store.write(
      _rankKey,
      jsonEncode({for (final e in own.entries) e.key: e.value.toJson()}),
    );
  }

  List<Correction> _readCorrections() {
    final raw = _store.read(_correctionKey);
    if (raw == null) return DemoSeed.corrections(_clock());
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return [
      for (final e in map.entries)
        Correction.fromJson(e.value as Map<String, dynamic>, e.key),
    ];
  }

  Future<void> _writeCorrections(List<Correction> list) => _store.write(
    _correctionKey,
    jsonEncode({for (final c in list) c.id: c.toJson()}),
  );

  @override
  Future<List<Correction>> fetchCorrectionsForOwner(String ownerId) async => [
    for (final c in _readCorrections())
      if (c.ownerId == ownerId) c,
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<List<Correction>> fetchCorrectionsByProposer(
    String proposerId,
  ) async => [
    for (final c in _readCorrections())
      if (c.proposerId == proposerId) c,
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> submitCorrection(Correction correction) async {
    final id = 'c-${_clock().microsecondsSinceEpoch}';
    final stored = Correction.fromJson(correction.toJson(), id);
    await _writeCorrections([..._readCorrections(), stored]);
  }

  @override
  Future<void> resolveCorrection(
    String correctionId,
    CorrectionStatus status,
  ) async {
    await _writeCorrections([
      for (final c in _readCorrections())
        c.id == correctionId ? c.copyWith(status: status) : c,
    ]);
  }
}
