import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Placeholder Firebase configuration generated in the same shape as
/// `flutterfire configure`. Replace the values with the ones from your
/// actual Firebase project (or re-run `flutterfire configure`) before
/// building a release build.
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
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBeVGoyXga-l8q2KLqvhZ2TMBfqC2jt1lg',
    appId: '1:333656314976:web:7d8d927b2a9e7576c3df05',
    messagingSenderId: '333656314976',
    projectId: 'workforce-f9e89',
    authDomain: 'workforce-f9e89.firebaseapp.com',
    storageBucket: 'workforce-f9e89.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDG0_I7mV5_OyaWRXkTVPnLIFW23voeQPI',
    appId: '1:333656314976:android:f2b679250a34a457c3df05',
    messagingSenderId: '333656314976',
    projectId: 'workforce-f9e89',
    storageBucket: 'workforce-f9e89.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBmVtwtsInEeLw_cVDGatEjKP8abOq4rz8',
    appId: '1:333656314976:ios:485178f3add1231fc3df05',
    messagingSenderId: '333656314976',
    projectId: 'workforce-f9e89',
    storageBucket: 'workforce-f9e89.firebasestorage.app',
    iosBundleId: 'com.example.workforceApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBmVtwtsInEeLw_cVDGatEjKP8abOq4rz8',
    appId: '1:333656314976:ios:485178f3add1231fc3df05',
    messagingSenderId: '333656314976',
    projectId: 'workforce-f9e89',
    storageBucket: 'workforce-f9e89.firebasestorage.app',
    iosBundleId: 'com.example.workforceApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBeVGoyXga-l8q2KLqvhZ2TMBfqC2jt1lg',
    appId: '1:333656314976:web:65856552f6a6d702c3df05',
    messagingSenderId: '333656314976',
    projectId: 'workforce-f9e89',
    authDomain: 'workforce-f9e89.firebaseapp.com',
    storageBucket: 'workforce-f9e89.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'REPLACE_WITH_LINUX_API_KEY',
    appId: 'REPLACE_WITH_LINUX_APP_ID',
    messagingSenderId: 'REPLACE_WITH_LINUX_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_STORAGE_BUCKET',
  );
}
