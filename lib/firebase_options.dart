// ignore_for_file: type=lint

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
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform. '
          'Run `flutterfire configure` to add it.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDkoRbjvcTTJiRRQ90bkcKQd4BEs7N4sVM',
    appId: '1:384780608424:web:4aa23cfe101ea698fbb39d',
    messagingSenderId: '384780608424',
    projectId: 'incident-report-app-f49b9',
    authDomain: 'incident-report-app-f49b9.firebaseapp.com',
    storageBucket: 'incident-report-app-f49b9.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCaGUgo8NLeH2a8b3SnRTENmXVT35fQz9s',
    appId: '1:384780608424:android:dc0419a5e4f33ebdfbb39d',
    messagingSenderId: '384780608424',
    projectId: 'incident-report-app-f49b9',
    storageBucket: 'incident-report-app-f49b9.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA0y0jXd-abcCUengiR_3Cu6f10-LnBzTI',
    appId: '1:384780608424:ios:a5bf7e96364ba231fbb39d',
    messagingSenderId: '384780608424',
    projectId: 'incident-report-app-f49b9',
    storageBucket: 'incident-report-app-f49b9.firebasestorage.app',
    iosBundleId: 'com.example.campusIncidentApp',
  );
}
