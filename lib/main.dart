import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/dependencies.dart';
import 'config/app_config.dart';
import 'data/key_value_store.dart';
import 'firebase_options.dart';
import 'ui/setup_error_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await SharedPrefsStore.open();

  if (AppConfig.demoMode) {
    runApp(TechDictionaryApp(dependencies: AppDependencies.demo(store)));
    return;
  }

  try {
    if (!DefaultFirebaseOptions.isConfigured) {
      throw StateError('Firebase is not configured.');
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    debugPrint('Firebase initialisation failed: $error');
    runApp(const SetupErrorApp());
    return;
  }
  runApp(TechDictionaryApp(dependencies: AppDependencies.firebase(store)));
}
