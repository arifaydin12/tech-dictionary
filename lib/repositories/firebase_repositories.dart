import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/community.dart';
import '../models/user_progress.dart';
import '../models/word.dart';
import 'repositories.dart';

String _authMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'weak-password':
      return 'The password is too weak. Use at least 6 characters.';
    case 'email-already-in-use':
      return 'An account with this email address already exists.';
    case 'invalid-email':
      return 'The email address is not valid.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Incorrect email or password.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    case 'operation-not-allowed':
      return 'This sign-in method is not enabled for the project.';
    case 'network-request-failed':
      return 'Network error. Check your internet connection.';
    case 'popup-closed-by-user':
    case 'canceled':
    case 'cancelled-popup-request':
      return 'Sign-in was cancelled.';
    default:
      return 'Authentication failed (${e.code}). Please try again.';
  }
}

AppUser _toAppUser(User user) {
  final email = user.email;
  final name = user.displayName;
  return AppUser(
    id: user.uid,
    email: email,
    displayName: (name != null && name.trim().isNotEmpty)
        ? name
        : (email != null ? email.split('@').first : 'Learner'),
  );
}

/// Firebase Authentication (email/password and Google).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  bool get supportsAccounts => true;

  @override
  Future<AppUser?> restoreSession() async {
    final user = await _auth.authStateChanges().first.timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );
    return user == null ? null : _toAppUser(user);
  }

  Future<AppUser> _guard(Future<User?> Function() action) async {
    try {
      final user = await action();
      if (user == null) {
        throw const RepositoryException('Sign-in failed. Please try again.');
      }
      return _toAppUser(user);
    } on FirebaseAuthException catch (e) {
      throw RepositoryException(_authMessage(e));
    }
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) => _guard(
    () async => (await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    )).user,
  );

  @override
  Future<AppUser> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) => _guard(() async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null && displayName.trim().isNotEmpty) {
      await user.updateDisplayName(displayName.trim());
      await user.reload();
    }
    return _auth.currentUser;
  });

  @override
  Future<AppUser> signInWithGoogle() => _guard(() async {
    final provider = GoogleAuthProvider()..addScope('email');
    final credential = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);
    return credential.user;
  });

  @override
  Future<AppUser> signInAsGuest() => throw const RepositoryException(
    'Guest mode is only available in demo mode.',
  );

  @override
  Future<void> signOut() => _auth.signOut();
}

/// Runs a Firestore call and converts failures to a [RepositoryException].
Future<T> _firestore<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on FirebaseException catch (e) {
    debugPrint('Firestore error: ${e.code}');
    if (e.code == 'permission-denied') {
      throw const RepositoryException(
        'You do not have permission to do that. Check your Firestore rules.',
      );
    }
    if (e.code == 'unavailable') {
      throw const RepositoryException(
        'The server is unreachable. Check your connection and try again.',
      );
    }
    throw RepositoryException('Could not reach the database (${e.code}).');
  }
}

/// Community words in the top-level `words` collection.
class FirestoreWordRepository implements WordRepository {
  FirestoreWordRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _words =>
      _db.collection('words');

  @override
  Future<List<Word>> fetchCommunityWords() => _firestore(() async {
    final snapshot = await _words.get();
    final words = <Word>[];
    for (final doc in snapshot.docs) {
      try {
        words.add(Word.fromJson(doc.data(), id: doc.id));
      } catch (e) {
        debugPrint('Skipping malformed word ${doc.id}: $e');
      }
    }
    return words;
  });

  @override
  Future<Word> addWord(Word draft, AppUser author) => _firestore(() async {
    final created = DateTime.now();
    final data = Word(
      id: '',
      term: draft.term,
      definition: draft.definition,
      category: draft.category,
      example: draft.example,
      authorId: author.id,
      authorName: author.displayName,
      createdAt: created,
    ).toJson()..remove('id');
    final ref = await _words.add(data);
    return Word.fromJson(data, id: ref.id);
  });

  @override
  Future<void> updateWord(Word word) => _firestore(() async {
    final data = word.toJson()..remove('id');
    await _words.doc(word.id).update(data);
  });

  @override
  Future<void> deleteWord(String wordId) =>
      _firestore(() => _words.doc(wordId).delete());
}

/// Progress stored as one JSON document at `users/{uid}/private/progress`.
class FirestoreProgressRepository implements ProgressRepository {
  FirestoreProgressRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String userId) =>
      _db.collection('users').doc(userId).collection('private').doc('progress');

  @override
  Future<UserProgress> load(String userId) => _firestore(() async {
    final snapshot = await _doc(userId).get();
    final raw = snapshot.data()?['json'];
    if (raw is! String) return UserProgress();
    try {
      return UserProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Ignoring unreadable progress document: $e');
      return UserProgress();
    }
  });

  @override
  Future<void> save(String userId, UserProgress progress) =>
      _firestore(() async {
        await _doc(userId).set({
          'json': jsonEncode(progress.toJson()),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      });
}

/// Leaderboard (`rankings`) and correction suggestions (`corrections`).
class FirestoreCommunityRepository implements CommunityRepository {
  FirestoreCommunityRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<List<RankingEntry>> fetchRankings() => _firestore(() async {
    final snapshot = await _db
        .collection('rankings')
        .orderBy('totalXp', descending: true)
        .limit(100)
        .get();
    return [
      for (final doc in snapshot.docs)
        RankingEntry.fromJson(doc.data(), doc.id),
    ];
  });

  @override
  Future<void> publishRanking(RankingEntry entry) => _firestore(
    () => _db.collection('rankings').doc(entry.userId).set(entry.toJson()),
  );

  Future<List<Correction>> _query(String field, String userId) =>
      _firestore(() async {
        final snapshot = await _db
            .collection('corrections')
            .where(field, isEqualTo: userId)
            .get();
        return [
          for (final doc in snapshot.docs)
            Correction.fromJson(doc.data(), doc.id),
        ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });

  @override
  Future<List<Correction>> fetchCorrectionsForOwner(String ownerId) =>
      _query('ownerId', ownerId);

  @override
  Future<List<Correction>> fetchCorrectionsByProposer(String proposerId) =>
      _query('proposerId', proposerId);

  @override
  Future<void> submitCorrection(Correction correction) =>
      _firestore(() => _db.collection('corrections').add(correction.toJson()));

  @override
  Future<void> resolveCorrection(String id, CorrectionStatus status) =>
      _firestore(
        () => _db.collection('corrections').doc(id).update({
          'status': status.name,
        }),
      );
}
