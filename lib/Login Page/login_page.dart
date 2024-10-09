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
        title: Text('Welcome to Bank Nkhonde', style: TextStyle(fontWeight: FontWeight.bold)),
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
      padding: EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 40),
            _buildIcon(),
            SizedBox(height: 60),
            _buildEmailField(),
            SizedBox(height: 30),
            _buildPasswordField(),
            SizedBox(height: 20),
            _buildForgotPasswordButton(),
            SizedBox(height: 40),
            _buildLoginButtons(),
            SizedBox(height: 40),
            _buildErrorMessage(),
            SizedBox(height: 40),
            _buildRegistrationButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Icon(
      Icons.account_balance,
      size: 80,
      color: Colors.black,
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Email Address',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        prefixIcon: Icon(Icons.email, color: Colors.black),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'Password',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
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
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildLoginButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                isAdminLogin = true;
              });
              _submit();
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 18),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 5,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.admin_panel_settings, size: 24, color: Colors.white),
                SizedBox(width: 10),
                Text('Login as Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                isAdminLogin = false;
              });
              _submit();
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 18),
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 5,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, size: 24, color: Colors.white),
                SizedBox(width: 10),
                Text('Login as User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    if (errorMessage.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          errorMessage,
          style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildRegistrationButton(BuildContext context) {
    return Column(
      children: [
        Divider(color: Colors.black, thickness: 1.5),
        SizedBox(height: 10),
        Text(
          "Don't have an admin account?",
          style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        TextButton(
          style: TextButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 15)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RegistrationPage(),
              ),
            );
          },
          child: Text(
            'Register here',
            style: TextStyle(color: Colors.black, fontSize: 18, decoration: TextDecoration.underline),
          ),
        ),
      ],
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
        DocumentSnapshot userDoc =
            await _db.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;

          if (data != null) {
            String role = data['role'] ?? 'member';
            String groupName = data['groupName'] ?? 'No Group';

            if (isAdminLogin && role == 'admin') {
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
            } else if (!isAdminLogin && role == 'member') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => UserDashboard(
                    isAdmin: false,
                  ),
                ),
              );
            } else {
              setState(() {
                errorMessage = 'Invalid login attempt. Please check your role.';
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
      errorMessage = '';
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}