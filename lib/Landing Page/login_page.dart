import 'package:bank_nkhonde/Dashboard/User%20Dashboard/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Dashboard/admin_dashboard.dart';  // Import the admin dashboard page
import '../Account Management/registration_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLogin = true;
  bool isAdminLogin = false;  // Added to track login as admin or user
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String errorMessage = '';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Login' : 'Register'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isLogin ? 'Login to Bank Nkhonde' : 'Register for Bank Nkhonde',
              style: TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email Address'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            
            // Admin/User selection buttons for login
            if (isLogin)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Admin login
                      setState(() {
                        isAdminLogin = true;
                      });
                      _submit(); // Perform login as admin
                    },
                    child: Text('Login as Admin'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // User login
                      setState(() {
                        isAdminLogin = false;
                      });
                      _submit(); // Perform login as user
                    },
                    child: Text('Login as User'),
                  ),
                ],
              ),

            SizedBox(height: 10),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            TextButton(
              onPressed: () {
                // Clear the login form when switching to registration
                _emailController.clear();
                _passwordController.clear();
                setState(() {
                  isLogin = !isLogin;
                });
              },
              child: Text(isLogin
                  ? 'Don\'t have an account? Register here'
                  : 'Already have an account? Login here'),
            ),
            if (!isLogin) // Show buttons for registering as user or admin
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _navigateToRegistration(context, false); // User registration
                    },
                    child: Text('Register as User'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      _navigateToRegistration(context, true); // Admin registration
                    },
                    child: Text('Register as Admin'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToRegistration(BuildContext context, bool isAdmin) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationPage(isAdmin: isAdmin),
      ),
    );
  }

  void _submit() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Fetch user document from Firestore
        DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>?;

          if (data != null) {
            String role = data['role'] ?? 'user'; // Default to 'user' if role is not set
            String groupName = data['groupName'] ?? 'No Group';

            // Check the role and navigate to the appropriate dashboard
            if (isAdminLogin && role == 'admin') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminDashboard(
                    isAdmin: true,
                    groupName: groupName,
                    isAdminView: true, // Admin view by default
                  ),
                ),
              );
            } else if (!isAdminLogin && role == 'user') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => UserDashboard(), // Navigate to User Dashboard
                ),
              );
            } else {
              setState(() {
                errorMessage = 'Invalid role for the selected login option.';
              });
            }
          } else {
            setState(() {
              errorMessage = 'User data not found';
            });
          }
        } else {
          setState(() {
            errorMessage = 'User data not found';
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = _getErrorMessage(e);
      });
    } catch (e) {
      setState(() {
        errorMessage = 'An unknown error occurred. Please try again.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Improved FirebaseAuth-specific error handling
  String _getErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No user found for this email. Please register first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'The email address is not valid. Please check and try again.';
      default:
        return error.message ?? 'An unexpected error occurred. Please try again later.';
    }
  }
}
