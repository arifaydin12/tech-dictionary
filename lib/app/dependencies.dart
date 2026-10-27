import '../data/key_value_store.dart';
import '../repositories/firebase_repositories.dart';
import '../repositories/local_repositories.dart';
import '../repositories/repositories.dart';
import '../services/export_service.dart';
import '../services/speech_service.dart';

/// Everything the app needs from the outside world. Demo mode and Firebase
/// mode differ only in which repositories are plugged in here.
class AppDependencies {
  AppDependencies({
    required this.demoMode,
    required this.store,
    required this.auth,
    required this.words,
    required this.progress,
    required this.community,
    required this.speaker,
    this.export = const ExportService(),
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  /// Offline demo: no Firebase, guest sign-in, seeded data.
  factory AppDependencies.demo(
    KeyValueStore store, {
    Speaker? speaker,
    DateTime Function()? clock,
  }) {
    return AppDependencies(
      demoMode: true,
      store: store,
      auth: LocalAuthRepository(store),
      words: LocalWordRepository(store, clock: clock),
      progress: LocalProgressRepository(
        store,
        seedDemoHistory: true,
        clock: clock,
      ),
      community: LocalCommunityRepository(store, clock: clock),
      speaker: speaker ?? FlutterTtsSpeaker(),
      clock: clock,
    );
  }

  /// Firebase must be initialised before this is called.
  factory AppDependencies.firebase(KeyValueStore store, {Speaker? speaker}) {
    return AppDependencies(
      demoMode: false,
      store: store,
      auth: FirebaseAuthRepository(),
      words: FirestoreWordRepository(),
      progress: FirestoreProgressRepository(),
      community: FirestoreCommunityRepository(),
      speaker: speaker ?? FlutterTtsSpeaker(),
    );
  }

  final bool demoMode;
  final KeyValueStore store;
  final AuthRepository auth;
  final WordRepository words;
  final ProgressRepository progress;
  final CommunityRepository community;
  final Speaker speaker;
  final ExportService export;

  /// Source of the current time; replaced in tests.
  final DateTime Function() clock;
}
