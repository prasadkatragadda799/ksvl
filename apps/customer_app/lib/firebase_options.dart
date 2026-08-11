import 'package:firebase_core/firebase_core.dart';

import 'env.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: Env.firebaseApiKey,
    appId: Env.firebaseAppId,
    messagingSenderId: Env.firebaseMessagingSenderId,
    projectId: Env.firebaseProjectId,
    authDomain: Env.firebaseAuthDomain,
    storageBucket: Env.firebaseStorageBucket,
  );
}
