import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'splash_screen.dart'; // Import your splash screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initializes Firebase
  await FirebaseAppCheck.instance.activate();
  runApp(BankNkhondeApp()); // Starts the app
}

class BankNkhondeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bank Nkhonde', // App title
      theme: ThemeData(
        primarySwatch: Colors.green, // Theme settings
      ),
      home: SplashScreen(), // Set SplashScreen as the initial screen
    );
  }
}
