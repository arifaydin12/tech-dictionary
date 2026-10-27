import '../models/app_user.dart';
import '../models/community.dart';
import '../models/user_progress.dart';
import '../models/word.dart';

/// Authentication. The Firebase implementation talks to Firebase Auth; the
/// local implementation signs in a guest without any network.
abstract class AuthRepository {
  /// The user restored from a previous session, if any.
  Future<AppUser?> restoreSession();

  Future<AppUser> signInWithEmail(String email, String password);

  Future<AppUser> signUpWithEmail(
    String email,
    String password,
    String displayName,
  );

  Future<AppUser> signInWithGoogle();

  Future<AppUser> signInAsGuest();

  Future<void> signOut();

  /// Whether [signInWithEmail] / [signUpWithEmail] / [signInWithGoogle] work.
  bool get supportsAccounts;
}

/// Storage of user-created ("community") words. The built-in dictionary is not
/// stored in a repository; it ships with the app.
abstract class WordRepository {
  Future<List<Word>> fetchCommunityWords();

  Future<Word> addWord(Word draft, AppUser author);

  Future<void> updateWord(Word word);

  Future<void> deleteWord(String wordId);
}

/// Per-user learning progress (cards, favourites, quiz history, XP, badges).
abstract class ProgressRepository {
  Future<UserProgress> load(String userId);

  Future<void> save(String userId, UserProgress progress);
}

/// Leaderboard and correction suggestions shared between users.
abstract class CommunityRepository {
  Future<List<RankingEntry>> fetchRankings();

  Future<void> publishRanking(RankingEntry entry);

  Future<List<Correction>> fetchCorrectionsForOwner(String ownerId);

  Future<List<Correction>> fetchCorrectionsByProposer(String proposerId);

  Future<void> submitCorrection(Correction correction);

  Future<void> resolveCorrection(String correctionId, CorrectionStatus status);
}

/// Thrown by repositories with a message that is safe to show to the user.
class RepositoryException implements Exception {
  const RepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
