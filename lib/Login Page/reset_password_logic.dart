import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

void resetPassword(String email, BuildContext context) {
  if (email.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your email to reset password.')));
  } else {
    _auth.sendPasswordResetEmail(email: email.trim()).then((_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Password reset email sent!')));
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending password reset email.')));
    });
  }
}
