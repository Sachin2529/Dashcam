import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb and TargetPlatform

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web; // Handle web separately
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      // Add desktop options if needed
        throw UnsupportedError('Unsupported platform');
      default:
        throw UnsupportedError(
          'Unsupported platform: $defaultTargetPlatform.',
        );
    }
  }

  // Android options
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDc7RQAbrnsOXsqYT3raBxoCk5Lyr9IW4o',
    appId: '1:793134113290:android:728df00384bd5f7b5175f3',
    messagingSenderId: '793134113290',
    projectId: 'sist-bus-da6e0',
  );

  // iOS options
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBmM-kHBnMfDd7wNzutq1_pRu1BMq1xBJM',
    appId: '1:793134113290:ios:38538b01abceed125175f3',
    messagingSenderId: '793134113290',
    projectId: 'sist-bus-da6e0',
    iosBundleId: 'com.example.dashcam', // e.g., "com.example.yourapp"
  );

  // Web options
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyAQMpBT2aWcJbapwo4l95IbFnJaBVy1OcY",
    appId: "1:793134113290:web:96294ac57d3cef225175f3",
    messagingSenderId: "793134113290",
    projectId: "sist-bus-da6e0",
  );
}