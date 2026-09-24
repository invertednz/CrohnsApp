import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for project `gutmd-app`.
///
/// Firebase API keys are public identifiers, not secrets; data access is
/// enforced by Firestore security rules and Firebase Auth.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ios;
    }
    throw UnsupportedError(
      'Firebase is not configured for $defaultTargetPlatform. '
      'Register the app with `flutterfire configure --project=gutmd-app`.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB4I6bpC0Fcg9dHfEejFSw7vosffkV2epE',
    appId: '1:92205709815:web:1a91d2c37488a9397556f2',
    messagingSenderId: '92205709815',
    projectId: 'gutmd-app',
    authDomain: 'gutmd-app.firebaseapp.com',
    storageBucket: 'gutmd-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAp0RhAXz48kHSS7BCb_CfYfeSJp9Olcdk',
    appId: '1:92205709815:ios:b969b52963e3596f7556f2',
    messagingSenderId: '92205709815',
    projectId: 'gutmd-app',
    storageBucket: 'gutmd-app.firebasestorage.app',
    iosBundleId: 'top.helptothe.gutmd',
  );
}
