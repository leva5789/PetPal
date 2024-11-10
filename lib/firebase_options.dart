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
    apiKey: 'AIzaSyCA2LKwwdUpv4ubnIVHpCRl5Tjtm_VQdcE',
    appId: '1:669877264006:web:8183cbc3e6f6f458f53b07',
    messagingSenderId: '669877264006',
    projectId: 'petpal-9e193',
    authDomain: 'petpal-9e193.firebaseapp.com',
    storageBucket: 'petpal-9e193.firebasestorage.app',
    measurementId: 'G-RKKJ5PW0C0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDeqJq3cA16_xySg6iJfHXIRVEY2ULHX4g',
    appId: '1:669877264006:android:df09fe161a008241f53b07',
    messagingSenderId: '669877264006',
    projectId: 'petpal-9e193',
    storageBucket: 'petpal-9e193.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDzw_uGordXaao6oPkOb6XBdXN8U5qb6JI',
    appId: '1:669877264006:ios:1ccf731371efa311f53b07',
    messagingSenderId: '669877264006',
    projectId: 'petpal-9e193',
    storageBucket: 'petpal-9e193.firebasestorage.app',
    iosBundleId: 'com.example.petpal',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDzw_uGordXaao6oPkOb6XBdXN8U5qb6JI',
    appId: '1:669877264006:ios:1ccf731371efa311f53b07',
    messagingSenderId: '669877264006',
    projectId: 'petpal-9e193',
    storageBucket: 'petpal-9e193.firebasestorage.app',
    iosBundleId: 'com.example.petpal',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCA2LKwwdUpv4ubnIVHpCRl5Tjtm_VQdcE',
    appId: '1:669877264006:web:e20f34b6855c6201f53b07',
    messagingSenderId: '669877264006',
    projectId: 'petpal-9e193',
    authDomain: 'petpal-9e193.firebaseapp.com',
    storageBucket: 'petpal-9e193.firebasestorage.app',
    measurementId: 'G-2EG9T2KKE8',
  );

}