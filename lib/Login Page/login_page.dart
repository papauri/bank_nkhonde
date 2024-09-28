import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Dashboard/Admin Dashboard/admin_dashboard.dart';
import '../Dashboard/User Dashboard/user_dashboard.dart';
import '../Account Management/admin_registration_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isAdminLogin = false;
  bool isLoading = false;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login to Bank Nkhonde'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          _buildLoginForm(context),
          if (isLoading) Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20),
            _buildTitle(),
            SizedBox(height: 40),
            _buildEmailField(),
            SizedBox(height: 20),
            _buildPasswordField(),
            SizedBox(height: 10),
            _buildForgotPasswordButton(),
            SizedBox(height: 30),
            _buildLoginButtons(),
            SizedBox(height: 20),
            _buildErrorMessage(),
            SizedBox(height: 20),
            _buildRegistrationButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Icon(
          Icons.account_balance,
          size: 60,
          color: Colors.black,
        ),
        SizedBox(height: 10),
        Text(
          'Welcome to Bank Nkhonde',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Email Address',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.email, color: Colors.black),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'Password',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.lock, color: Colors.black),
      ),
      obscureText: true,
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _resetPassword,
        child: Text(
          'Forgot Password?',
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildLoginButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLoginButton(
          label: 'Login as Admin',
          icon: Icons.admin_panel_settings,
          isAdminLogin: true,
        ),
        _buildLoginButton(
          label: 'Login as User',
          icon: Icons.person,
          isAdminLogin: false,
        ),
      ],
    );
  }

  Widget _buildLoginButton(
      {required String label,
      required IconData icon,
      required bool isAdminLogin}) {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          this.isAdminLogin = isAdminLogin;
        });
        _submit();
      },
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        backgroundColor: Colors.black, // Background color
        foregroundColor: Colors.white, // Text color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (errorMessage.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          errorMessage,
          style: TextStyle(color: Colors.red, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildRegistrationButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        // Navigate to Admin registration page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegistrationPage(),
          ),
        );
      },
      child: Text(
        'Don\'t have an admin account? Register here',
        style: TextStyle(color: Colors.black),
      ),
    );
  }

  void _resetPassword() {
    if (_emailController.text.isEmpty) {
      setState(() {
        errorMessage = 'Please enter your email to reset password.';
      });
    } else {
      _auth
          .sendPasswordResetEmail(email: _emailController.text.trim())
          .then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password reset email sent!')));
      }).catchError((e) {
        setState(() {
          errorMessage = 'Error sending password reset email.';
        });
      });
    }
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
        DocumentSnapshot userDoc =
            await _db.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>?;

          if (data != null) {
            String role = data['role'] ?? 'member';
            String groupName = data['groupName'] ?? 'No Group';

            // Navigate based on the role stored in Firestore
            if (role == 'admin') {
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
            } else if (role == 'member') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      UserDashboard(), // Navigate to the user dashboard
                ),
              );
            } else {
              setState(() {
                errorMessage = 'Invalid role. Please contact support.';
              });
            }
          }
        } else {
          setState(() {
            errorMessage = 'User data not found.';
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = _getErrorMessage(e);
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

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
        return 'The email address is invalid. Please check and try again.';
      default:
        return error.message ??
            'An unexpected error occurred. Please try again later.';
    }
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearErrorMessage);
    _passwordController.addListener(_clearErrorMessage);
  }

  void _clearErrorMessage() {
    setState(() {
      errorMessage =
          ''; // Clears error message when user interacts with input fields
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
