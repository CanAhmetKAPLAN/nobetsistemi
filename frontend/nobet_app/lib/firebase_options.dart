// Bu dosyayı FlutterFire CLI ile oluştur:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Veya Firebase Console'dan değerleri aşağıya yapıştır.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  // 🔧 Firebase Console → Project Settings → Your apps → Web app
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBE1A1VkNdylEMClP5KlIlu-vdPRTt_a24",
  authDomain: "asker-nobet-sistemi.firebaseapp.com",
  projectId: "asker-nobet-sistemi",
  storageBucket: "asker-nobet-sistemi.firebasestorage.app",
  messagingSenderId: "897670122048",
  appId: "1:897670122048:web:bd5ad001f64c15a2a92da5",
  measurementId: "G-1WKBK58BGP"
  );

  // 🔧 Firebase Console → Project Settings → Your apps → Android app
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBE1A1VkNdylEMClP5KlIlu-vdPRTt_a24",
  authDomain: "asker-nobet-sistemi.firebaseapp.com",
  projectId: "asker-nobet-sistemi",
  storageBucket: "asker-nobet-sistemi.firebasestorage.app",
  messagingSenderId: "897670122048",
  appId: "1:897670122048:web:bd5ad001f64c15a2a92da5",
  measurementId: "G-1WKBK58BGP"
  );

  // 🔧 Firebase Console → Project Settings → Your apps → iOS app
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyBE1A1VkNdylEMClP5KlIlu-vdPRTt_a24",
  authDomain: "asker-nobet-sistemi.firebaseapp.com",
  projectId: "asker-nobet-sistemi",
  storageBucket: "asker-nobet-sistemi.firebasestorage.app",
  messagingSenderId: "897670122048",
  appId: "1:897670122048:web:bd5ad001f64c15a2a92da5",
  measurementId: "G-1WKBK58BGP"
  );

  // 🔧 Firebase Console → Project Settings → Your apps → Web app (Windows için web kullan)
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: "AIzaSyBE1A1VkNdylEMClP5KlIlu-vdPRTt_a24",
  authDomain: "asker-nobet-sistemi.firebaseapp.com",
  projectId: "asker-nobet-sistemi",
  storageBucket: "asker-nobet-sistemi.firebasestorage.app",
  messagingSenderId: "897670122048",
  appId: "1:897670122048:web:bd5ad001f64c15a2a92da5",
  measurementId: "G-1WKBK58BGP"
  );
}
