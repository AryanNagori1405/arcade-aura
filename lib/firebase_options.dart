import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Configure Firebase for this platform.');
    }
  }

  static const android = FirebaseOptions(
    apiKey: 'ADD_ANDROID_API_KEY',
    appId: 'ADD_ANDROID_APP_ID',
    messagingSenderId: 'ADD_SENDER_ID',
    projectId: 'ADD_PROJECT_ID',
  );

  static const ios = FirebaseOptions(
    apiKey: 'ADD_IOS_API_KEY',
    appId: 'ADD_IOS_APP_ID',
    messagingSenderId: 'ADD_SENDER_ID',
    projectId: 'ADD_PROJECT_ID',
    iosBundleId: 'com.example.arcadeAura',
  );

  static const web = FirebaseOptions(
    apiKey: 'ADD_WEB_API_KEY',
    appId: 'ADD_WEB_APP_ID',
    messagingSenderId: 'ADD_SENDER_ID',
    projectId: 'ADD_PROJECT_ID',
    authDomain: 'ADD_PROJECT.firebaseapp.com',
    storageBucket: 'ADD_PROJECT.firebasestorage.app',
  );
}
