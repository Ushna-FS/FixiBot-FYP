// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCcwzteipCGdwPHtsH2a-e8TctVBnxzJHE',
    appId: '1:90736648729:web:3e3b54a46606564f690088',
    messagingSenderId: '90736648729',
    projectId: 'autoassist-53928',
    authDomain: 'autoassist-53928.firebaseapp.com',
    storageBucket: 'autoassist-53928.firebasestorage.app',
    measurementId: 'G-EVH5HV86KE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBLoIwYCxS7n7EQONboP4U_IJl6Isp-iy4',
    appId: '1:90736648729:android:42b51965d48228bc690088',
    messagingSenderId: '90736648729',
    projectId: 'autoassist-53928',
    storageBucket: 'autoassist-53928.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCylSTMMLym2E_V9bcu6vgLZGM5xRR5z4o',
    appId: '1:90736648729:ios:7d5a503a87220bd7690088',
    messagingSenderId: '90736648729',
    projectId: 'autoassist-53928',
    storageBucket: 'autoassist-53928.firebasestorage.app',
    iosBundleId: 'com.example.fixibotApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCylSTMMLym2E_V9bcu6vgLZGM5xRR5z4o',
    appId: '1:90736648729:ios:7d5a503a87220bd7690088',
    messagingSenderId: '90736648729',
    projectId: 'autoassist-53928',
    storageBucket: 'autoassist-53928.firebasestorage.app',
    iosBundleId: 'com.example.fixibotApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCcwzteipCGdwPHtsH2a-e8TctVBnxzJHE',
    appId: '1:90736648729:web:45d6aef5c5a58b6c690088',
    messagingSenderId: '90736648729',
    projectId: 'autoassist-53928',
    authDomain: 'autoassist-53928.firebaseapp.com',
    storageBucket: 'autoassist-53928.firebasestorage.app',
    measurementId: 'G-LY2PSE84YZ',
  );
}
