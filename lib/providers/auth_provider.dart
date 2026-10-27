import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../repositories/repositories.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository);

  final AuthRepository _repository;

  AppUser? _user;
  bool _initialising = true;
  bool _busy = false;
  String? _error;

  AppUser? get user => _user;
  bool get isSignedIn => _user != null;

  /// True until the previous session has been restored.
  bool get initialising => _initialising;
  bool get busy => _busy;
  String? get error => _error;
  bool get supportsAccounts => _repository.supportsAccounts;

  Future<void> init() async {
    try {
      _user = await _repository.restoreSession();
    } catch (e) {
      debugPrint('Could not restore session: $e');
      _user = null;
    }
    _initialising = false;
    notifyListeners();
  }

  Future<bool> _run(Future<AppUser> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _user = await action();
      return true;
    } on RepositoryException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      debugPrint('Unexpected auth error: $e');
      _error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail(String email, String password) =>
      _run(() => _repository.signInWithEmail(email, password));

  Future<bool> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) => _run(() => _repository.signUpWithEmail(email, password, displayName));

  Future<bool> signInWithGoogle() => _run(_repository.signInWithGoogle);

  Future<bool> signInAsGuest() => _run(_repository.signInAsGuest);

  Future<void> signOut() async {
    await _repository.signOut();
    _user = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}
