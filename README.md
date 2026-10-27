# Tech Dictionary

A cross-platform **Flutter** app for learning information-technology terms ("bilişim kavramları"). Users build a personal dictionary, test themselves with quizzes, earn badges, climb a ranking and keep learning offline. Authentication and cloud sync run on **Firebase**.

## Features

**Learning**
- Personal word list with terms, definitions, categories, favourites and attached images
- Quizzes with scoring, plus a review queue of words that still need practice
- Fuzzy search that tolerates typos
- Text-to-speech pronunciation
- A lightweight suggestion engine for categories and similar words

**Motivation**
- Gamification: progress tracking and unlockable badges for adding words and finishing quizzes
- Global ranking and advanced statistics with charts (`fl_chart`)
- Onboarding flow, local notifications and Firebase Cloud Messaging

**Community**
- Suggest corrections to a term and moderate suggestions
- Social interactions around shared words
- Export your dictionary to PDF and share it

**Platform**
- Email/password and Google sign-in (Firebase Auth)
- Cloud sync with Cloud Firestore and Firebase Storage
- Offline support with Hive and connectivity detection
- Optional biometric authentication and AES encryption helpers for sensitive data
- Light and dark themes, responsive layouts, and Flutter targets for Android, iOS, web, Windows, macOS and Linux

## Architecture

State is managed with **Provider**; business logic lives in services so screens stay thin.

```
lib/
  config/       Theme, constants, responsive helpers
  models/       Word, quiz question, badge, user profile, ranking, ...
  providers/    Auth, theme, user and word state (Provider)
  services/     Firebase, quiz, gamification, learning, search, offline,
                notifications, TTS, export, social, security, suggestions
  screens/      Home, quiz, stats, ranking, profile, settings, onboarding, ...
  widgets/      Reusable UI components
```

## Getting started

**Prerequisites:** [Flutter](https://docs.flutter.dev/get-started/install) 3.9+ and a Firebase project.

1. **Install dependencies**

   ```bash
   flutter pub get
   ```

2. **Connect your Firebase project.** Credentials are intentionally not committed (`YOUR_FIREBASE_API_KEY` is a placeholder). Generate your own configuration:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   This regenerates `lib/firebase_options.dart` and downloads `google-services.json` and `GoogleService-Info.plist`.

3. **In the Firebase console**, enable *Authentication* (Email/Password and Google) and *Cloud Firestore*, then deploy the included rules:

   ```bash
   firebase deploy --only firestore:rules
   ```

   The rules in [`firestore.rules`](firestore.rules) restrict every user to their own documents.

4. **Run**

   ```bash
   flutter run
   ```

   For Google sign-in on Android, add your debug SHA-1 fingerprint (`cd android && ./gradlew signingReport`) to the Firebase project.

## Notes

The user interface is in Turkish.

## License

[MIT](LICENSE) © Arif Enes
