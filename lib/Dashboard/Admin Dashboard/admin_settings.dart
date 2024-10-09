import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bank_nkhonde/Dashboard/Admin%20Dashboard/admin_dashboard.dart';

class AdminSettingsPage extends StatefulWidget {
  @override
  _AdminSettingsPageState createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isLoading = false;
  String errorMessage = '';
  bool isNameChanged = false;
  bool isEmailChanged = false;
  bool isPhoneChanged = false;

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _nameController.text = userDoc['name'] ?? '';
          _emailController.text = user.email ?? '';
          _phoneController.text = userDoc['phone'] ?? '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader('Personal Information'),
              SizedBox(height: 10),
              _buildNameField(),
              SizedBox(height: 20),
              _buildEmailField(),
              SizedBox(height: 20),
              _buildPhoneField(),
              SizedBox(height: 30),
              _buildSectionHeader('Security'),
              SizedBox(height: 10),
              _buildChangePasswordField(),
              SizedBox(height: 30),
              _buildUpdateProfileButton(),
              if (errorMessage.isNotEmpty) ...[
                SizedBox(height: 20),
                _buildErrorMessage(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      onChanged: (value) {
        setState(() {
          isNameChanged = true;
        });
      },
      decoration: InputDecoration(
        labelText: 'Full Name',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        prefixIcon: Icon(Icons.person, color: Colors.black),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      onChanged: (value) {
        setState(() {
          isEmailChanged = true;
        });
      },
      decoration: InputDecoration(
        labelText: 'Email Address',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        prefixIcon: Icon(Icons.email, color: Colors.black),
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPhoneField() {
    return TextField(
      controller: _phoneController,
      onChanged: (value) {
        setState(() {
          isPhoneChanged = true;
        });
      },
      decoration: InputDecoration(
        labelText: 'Phone Number',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        prefixIcon: Icon(Icons.phone, color: Colors.black),
      ),
      keyboardType: TextInputType.phone,
    );
  }

  Widget _buildChangePasswordField() {
    return TextField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'New Password',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        prefixIcon: Icon(Icons.lock, color: Colors.black),
      ),
      obscureText: true,
    );
  }

  Widget _buildUpdateProfileButton() {
    return ElevatedButton(
      onPressed: _showPasswordDialog,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 18),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 5,
      ),
      child: isLoading
          ? CircularProgressIndicator(color: Colors.white)
          : Text('Update Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildErrorMessage() {
    return Text(
      errorMessage,
      style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }

  void _showPasswordDialog() {
    String updatedFields = _getUpdatedFields();
    if (updatedFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No changes made.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Your Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter your current password to confirm changes to: $updatedFields'),
              SizedBox(height: 10),
              TextField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.black),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateProfile();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  String _getUpdatedFields() {
    List<String> updatedFields = [];
    if (isNameChanged) updatedFields.add('Full Name');
    if (isEmailChanged) updatedFields.add('Email Address');
    if (isPhoneChanged) updatedFields.add('Phone Number');
    return updatedFields.join(', ');
  }

  void _updateProfile() async {
    if (_currentPasswordController.text.isEmpty) {
      setState(() {
        errorMessage = 'Please enter your current password.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Reauthenticate user
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text.trim(),
        );
        await user.reauthenticateWithCredential(credential);

        // Update Firestore user document
        if (isNameChanged || isPhoneChanged) {
          await _db.collection('users').doc(user.uid).update({
            if (isNameChanged) 'name': _nameController.text.trim(),
            if (isPhoneChanged) 'phone': _phoneController.text.trim(),
          });
        }

        // Update email
        if (isEmailChanged) {
          await user.updateEmail(_emailController.text.trim());
        }

        // Update password if provided
        if (_passwordController.text.isNotEmpty) {
          await user.updatePassword(_passwordController.text.trim());
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
        _passwordController.clear();
        _currentPasswordController.clear();
        setState(() {
          isNameChanged = false;
          isEmailChanged = false;
          isPhoneChanged = false;
        });

        // Automatically update the admin dashboard with changes
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminDashboard(isAdmin: true, groupName: 'Your Group Name')),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = _getErrorMessage(e);
      });
    } catch (e) {
      setState(() {
        errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      case 'requires-recent-login':
        return 'Please re-authenticate and try again.';
      case 'invalid-email':
        return 'The email address is invalid. Please check and try again.';
      case 'wrong-password':
        return 'The current password is incorrect. Please try again.';
      default:
        return error.message ?? 'An unexpected error occurred. Please try again later.';
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _currentPasswordController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}