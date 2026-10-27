import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:convert';
import '../models/word.dart';
import '../services/firebase_service.dart';

class OfflineService {
  static const String _wordsBoxName = 'words_box';
  static const String _pendingBoxName = 'pending_changes';
  Box<String>? _wordsBox;
  Box<String>? _pendingBox;
  bool _isInitialized = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    _wordsBox = await Hive.openBox<String>(_wordsBoxName);
    _pendingBox = await Hive.openBox<String>(_pendingBoxName);

    _isInitialized = true;

    // Connectivity listener
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      if (result != ConnectivityResult.none) {
        _syncPendingChanges();
      }
    });
  }

  Future<bool> get isOnline async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Kelimeleri local'e kaydet
  Future<void> saveWordLocally(Word word) async {
    if (!_isInitialized) await initialize();

    final wordId = word.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    await _wordsBox?.put(wordId, jsonEncode(word.toJson()));

    // Eğer offline ise, pending'e ekle
    if (!(await isOnline)) {
      await _pendingBox?.put(
        'word_$wordId',
        jsonEncode({'action': 'add', 'word': word.toJson()}),
      );
    }
  }

  // Local kelimeleri al
  List<Word> getLocalWords() {
    if (!_isInitialized) return [];

    final words = <Word>[];
    for (var key in _wordsBox!.keys) {
      try {
        final jsonString = _wordsBox!.get(key);
        if (jsonString != null) {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          words.add(Word.fromJson(json));
        }
      } catch (e) {
        print('Kelime parse hatası: $e');
      }
    }
    return words;
  }

  // Pending değişiklikleri senkronize et
  Future<void> _syncPendingChanges() async {
    if (!_isInitialized || _pendingBox == null) return;

    final firebaseService = FirebaseService();
    if (!firebaseService.isLoggedIn) return;

    final pendingKeys = _pendingBox!.keys.toList();

    for (final key in pendingKeys) {
      try {
        final changeString = _pendingBox!.get(key);
        if (changeString == null) continue;

        final change = jsonDecode(changeString) as Map<String, dynamic>;
        final action = change['action'] as String;
        final wordData = change['word'] as Map<String, dynamic>;
        final word = Word.fromJson(wordData);

        switch (action) {
          case 'add':
            await firebaseService.saveWord(word);
            break;
          case 'update':
            await firebaseService.updateWord(word);
            break;
          case 'delete':
            if (word.id != null) {
              await firebaseService.deleteWord(word.id!);
            }
            break;
        }

        // Başarılı olursa pending'den sil
        await _pendingBox?.delete(key);
      } catch (e) {
        print('Senkronizasyon hatası: $e');
      }
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
