import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyBSXHCZp61uyYTSZFlEfyezPnmR9Df72B4",
            authDomain: "fitty-f9ff5.firebaseapp.com",
            projectId: "fitty-f9ff5",
            storageBucket: "fitty-f9ff5.appspot.com",
            messagingSenderId: "923773604207",
            appId: "1:923773604207:web:52b66e6cc6efaa60bc189a",
            measurementId: "G-XNJKLHZ9DC"));
  } else {
    await Firebase.initializeApp();
  }
}
