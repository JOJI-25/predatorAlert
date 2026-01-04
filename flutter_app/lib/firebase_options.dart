/// Firebase configuration for Predator Alert System
/// 
/// Generated from google-services.json

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDW3bNBldVn6909ZaY5G-3orKxbMIdD-Mo',
    appId: '1:798005677284:android:0dcbfa827d1dbf710c30f1',
    messagingSenderId: '798005677284',
    projectId: 'predatoralert-system',
    storageBucket: 'predatoralert-system.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDW3bNBldVn6909ZaY5G-3orKxbMIdD-Mo',
    appId: '1:798005677284:android:0dcbfa827d1dbf710c30f1',
    messagingSenderId: '798005677284',
    projectId: 'predatoralert-system',
    storageBucket: 'predatoralert-system.firebasestorage.app',
    iosBundleId: 'com.predatoralert.app',
  );
}

