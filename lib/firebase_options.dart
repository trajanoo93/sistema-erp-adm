import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: "AIzaSyCMEGw71T-RxFLtEbgEQiqhXiaHXa6HY0",
        authDomain: "ao-gosto-app-c0b31.firebaseapp.com",
        projectId: "ao-gosto-app-c0b31",
        storageBucket: "ao-gosto-app-c0b31.appspot.com",
        messagingSenderId: "932043130642",
        appId: "1:932043130642:web:e85183f93e41b65ee955cb",
        measurementId: "G-VKQBFM2WER",
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      // ✅ usa o mesmo app Apple (iOS/macOS)
      return const FirebaseOptions(
        apiKey: "AIzaSyAaRtV042woLZ3WeycVlL3ORsLWTkzi5S8",
        appId: "1:932043130642:ios:9a998f8e68ac27dce955cb",
        messagingSenderId: "932043130642",
        projectId: "ao-gosto-app-c0b31",
        storageBucket: "ao-gosto-app-c0b31.appspot.com",
      );
    } else {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not supported for this platform.',
      );
    }
  }
}
