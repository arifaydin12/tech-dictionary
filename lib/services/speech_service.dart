import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Reads text aloud. Implementations must never throw.
abstract class Speaker {
  /// Whether speech output is expected to work on this platform.
  bool get isAvailable;

  Future<void> speak(String text, {double rate = 0.5});

  Future<void> stop();
}

/// Text-to-speech through the platform's speech engine (`flutter_tts`).
/// Errors, for example a browser without speech synthesis, are swallowed so
/// the UI keeps working.
class FlutterTtsSpeaker implements Speaker {
  FlutterTts? _tts;
  bool _failed = false;

  @override
  bool get isAvailable => !_failed;

  Future<FlutterTts?> _engine() async {
    if (_failed) return null;
    try {
      final tts = _tts ??= FlutterTts();
      await tts.setLanguage('en-US');
      return tts;
    } catch (e) {
      debugPrint('Text-to-speech unavailable: $e');
      _failed = true;
      return null;
    }
  }

  @override
  Future<void> speak(String text, {double rate = 0.5}) async {
    final tts = await _engine();
    if (tts == null) return;
    try {
      await tts.setSpeechRate(rate);
      await tts.stop();
      await tts.speak(text);
    } catch (e) {
      debugPrint('Text-to-speech failed: $e');
      _failed = true;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}

/// A speaker that records what it was asked to say; used in tests and as a
/// safe fallback.
class SilentSpeaker implements Speaker {
  final List<String> spoken = [];

  @override
  bool get isAvailable => true;

  @override
  Future<void> speak(String text, {double rate = 0.5}) async =>
      spoken.add(text);

  @override
  Future<void> stop() async {}
}
