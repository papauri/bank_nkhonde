import 'package:bank_nkhonde/Login%20Page/login_page.dart'; // Handles login and registration
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initializes Firebase
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
      home: LoginPage(), // Navigates to the LoginPage
    );
  }
}
