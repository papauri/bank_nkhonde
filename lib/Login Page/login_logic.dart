import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Dashboard/Admin Dashboard/admin_dashboard.dart';
import '../Dashboard/User Dashboard/user_dashboard.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _db = FirebaseFirestore.instance;

void loginUser(String email, String password, bool isAdminLogin, BuildContext context, Function(bool, String) callback) async {
  bool isLoading = true;
  String errorMessage = '';
  callback(isLoading, errorMessage);

  try {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    User? user = userCredential.user;

    if (user != null) {
      DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        if (data != null) {
          String role = data['role'] ?? 'user';
          String groupName = data['groupName'] ?? 'No Group';

          if (role == 'admin' && isAdminLogin) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminDashboard(
                  groupName: groupName,
                  isAdminView: true,
                  isAdmin: true,
                ),
              ),
            );
          } else if (role == 'user' && !isAdminLogin) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => UserDashboard()),
            );
          } else {
            errorMessage = 'Invalid role for this login option.';
          }
        } else {
          errorMessage = 'User data not found.';
        }
      } else {
        errorMessage = 'User data not found.';
      }
    }
  } catch (e) {
    errorMessage = 'Login failed. Please try again.';
  } finally {
    isLoading = false;
    callback(isLoading, errorMessage);
  }
}
