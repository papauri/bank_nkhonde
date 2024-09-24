import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Dashboard/admin_dashboard.dart';  // Import the dashboard page

// Registration Page for Admin and User
class RegistrationPage extends StatefulWidget {
  final bool isAdmin;
  RegistrationPage({required this.isAdmin});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<String> groupNames = [];
  String selectedGroup = '';
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadGroupNames();
  }

  void _loadGroupNames() async {
    try {
      QuerySnapshot groupSnapshot = await _db.collection('groups').get();
      setState(() {
        if (groupSnapshot.docs.isNotEmpty) {
          groupNames = groupSnapshot.docs
              .map((doc) => doc['groupName'].toString())
              .toList();
          selectedGroup = groupNames.isNotEmpty ? groupNames.first : '';
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load groups. Please try again.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Register as Admin' : 'Register as User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email Address'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (!widget.isAdmin) // Group Name dropdown only for users
              isLoading
                  ? CircularProgressIndicator()
                  : groupNames.isEmpty
                      ? TextField(
                          controller: _groupController,
                          decoration: InputDecoration(
                            labelText: 'Group Name (Optional)',
                            hintText: 'No groups available',
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          value: selectedGroup.isNotEmpty ? selectedGroup : null,
                          decoration: InputDecoration(labelText: 'Group Name'),
                          onChanged: (value) {
                            setState(() {
                              selectedGroup = value!;
                            });
                          },
                          items: groupNames
                              .map((name) => DropdownMenuItem(
                                    value: name,
                                    child: Text(name),
                                  ))
                              .toList(),
                        ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerUser,
              child: Text('Register'),
            ),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

void _registerUser() async {
  String email = _emailController.text.trim();
  String password = _passwordController.text.trim();
  String name = _nameController.text.trim();
  String groupName = widget.isAdmin ? 'Admin' : selectedGroup;

  if (email.isEmpty || password.isEmpty || name.isEmpty) {
    setState(() {
      errorMessage = 'Please fill all required fields.';
    });
    return;
  }

  try {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    User? user = userCredential.user;

    if (user != null) {
      // Create both admin and user role for the admin
      if (widget.isAdmin) {
        await _db.collection('users').doc(user.uid).set({
          'name': name,
          'groupName': groupName,
          'email': email,
          'role': 'admin',
          'createdAt': Timestamp.now(),
        });
        await _db.collection('users').doc('${user.uid}_user').set({
          'name': name,
          'groupName': groupName,
          'email': email,
          'role': 'user',
          'createdAt': Timestamp.now(),
        });
      } else {
        await _db.collection('users').doc(user.uid).set({
          'name': name,
          'groupName': groupName,
          'email': email,
          'role': 'user',
          'createdAt': Timestamp.now(),
        });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminDashboard(
            isAdmin: widget.isAdmin,
            groupName: groupName,
            isAdminView: widget.isAdmin, // Show admin view if it's an admin
          ),
        ),
      );
    }
  } catch (e) {
    setState(() {
      errorMessage = _getErrorMessage(e);
    });
  }
}


  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'This email is already in use.';
        case 'weak-password':
          return 'The password is too weak.';
        case 'invalid-email':
          return 'The email address is invalid.';
        default:
          return 'An error occurred during registration.';
      }
    }
    return 'An unknown error occurred.';
  }
}
