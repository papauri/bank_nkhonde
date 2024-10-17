import 'dart:async';
import 'package:flutter/material.dart';
import 'Login Page/login_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Start a timer to navigate to the login page after 3 seconds
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size dynamically using MediaQuery
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/splash_image.png', // Make sure this path matches your image file
          fit: BoxFit.cover,
          width: screenSize.width,  // Dynamically set width
          height: screenSize.height, // Dynamically set height
        ),
      ),
    );
  }
}
