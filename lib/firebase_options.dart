import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return web; // Use web config for Windows
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  // Replace these values with your Firebase config from the console
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyABMBclJv8dwbV9Nip7QBYsjZuqpAcRf1Q',
    appId: '1:894201985190:web:8d5a91bfd3a6dc7e795c67',
    messagingSenderId: '894201985190',
    projectId: 'regent-connect-85439',
    authDomain: 'regent-connect-85439.firebaseapp.com',
    storageBucket: 'regent-connect-85439.firebasestorage.app',
    measurementId: 'G-W7RKWH6W2M',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyABMBclJv8dwbV9Nip7QBYsjZuqpAcRf1Q',
    appId: '1:894201985190:web:8d5a91bfd3a6dc7e795c67',
    messagingSenderId: '894201985190',
    projectId: 'regent-connect-85439',
    storageBucket: 'regent-connect-85439.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyABMBclJv8dwbV9Nip7QBYsjZuqpAcRf1Q',
    appId: '1:894201985190:web:8d5a91bfd3a6dc7e795c67',
    messagingSenderId: '894201985190',
    projectId: 'regent-connect-85439',
    storageBucket: 'regent-connect-85439.firebasestorage.app',
    iosBundleId: 'com.example.regentConnect',
  );
}
