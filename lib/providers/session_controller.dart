import 'package:flutter/foundation.dart';

import 'auth_provider.dart';
import 'community_provider.dart';
import 'dictionary_provider.dart';
import 'progress_provider.dart';

enum SessionStatus { signedOut, loading, ready }

/// Loads and clears the per-user providers when the signed-in user changes.
class SessionController extends ChangeNotifier {
  SessionController({
    required this.auth,
    required this.dictionary,
    required this.progress,
    required this.community,
  }) {
    auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final AuthProvider auth;
  final DictionaryProvider dictionary;
  final ProgressProvider progress;
  final CommunityProvider community;

  SessionStatus _status = SessionStatus.signedOut;
  String? _loadedUserId;

  SessionStatus get status => _status;

  /// The first error reported while loading the session, if any.
  String? get error => dictionary.error ?? progress.error ?? community.error;

  void _onAuthChanged() {
    final user = auth.user;
    if (user == null) {
      if (_loadedUserId != null || _status != SessionStatus.signedOut) {
        _loadedUserId = null;
        dictionary.clear();
        progress.clear();
        community.clear();
        _status = SessionStatus.signedOut;
        notifyListeners();
      }
      return;
    }
    if (user.id != _loadedUserId) {
      _loadedUserId = user.id;
      reload();
    }
  }

  /// (Re)loads dictionary, progress and community data for the current user.
  Future<void> reload() async {
    final user = auth.user;
    if (user == null) return;
    _status = SessionStatus.loading;
    notifyListeners();
    await Future.wait([
      dictionary.load(),
      progress.load(user),
      community.load(user),
    ]);
    if (auth.user?.id == user.id) {
      _status = SessionStatus.ready;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
