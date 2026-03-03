import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Firebase configuration for all platforms.
///
/// Replace every "YOUR_..." placeholder with the actual values from the
/// Firebase console:
///   1. Go to https://console.firebase.google.com
///   2. Open your project > Project Settings (gear icon) > General
///   3. Under "Your apps" click the Web icon (</>) — register any nickname,
///      no hosting needed. Firebase will show a `firebaseConfig` object with
///      all the values below.
///   4. The `databaseURL` is shown under Build > Realtime Database > Data tab.
///
/// After filling in the values run: `flutter pub get`
class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    databaseURL:
        'https://YOUR_PROJECT_ID-default-rtdb.REGION.firebasedatabase.app',
  );
}
