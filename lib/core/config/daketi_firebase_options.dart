import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Public Firebase client identifiers. Server signing keys are never bundled.
class DaketiFirebaseOptions {
  DaketiFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return ios;
    }
    throw UnsupportedError('Firebase push is configured for Android and iOS.');
  }

  static const android = FirebaseOptions(
    apiKey: "AIzaSyCe4tIQv3zI79SMFTTic25uiV4DZTds1Gw",
    appId: "1:367564985041:android:a755c79a52c9f41bb12bf0",
    messagingSenderId: "367564985041",
    projectId: "daketi-ea2dc",
  );

  static const ios = FirebaseOptions(
    apiKey: "AIzaSyBYkNGOQeLYCbA9cjpdfyx0LXuVaC9ytKA",
    appId: "1:367564985041:ios:64a989b67d67d7e6b12bf0",
    messagingSenderId: "367564985041",
    projectId: "daketi-ea2dc",
    iosBundleId: "de.zamedia.daketigame",
  );
}
