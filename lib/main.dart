import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'bus_tracking_screen.dart';
import 'boarding_point_screen.dart';
import 'firebase_options.dart'; // Ensure this path is correct

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use this for all platforms
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BusTrackingScreen(), // Removed const here
      routes: {
        '/boarding': (context) => const BoardingPointScreen(),
        '/bus-tracking': (context) => BusTrackingScreen(), // Removed const here as well
      },
    );
  }
}
