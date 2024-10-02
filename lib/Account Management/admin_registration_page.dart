import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Dashboard/Admin Dashboard/admin_dashboard.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  // Add a new controller for the invitation code
  final TextEditingController _invitationCodeController =
      TextEditingController();

  // Group creation fields
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _seedMoneyController = TextEditingController();
  final TextEditingController _interestRateController = TextEditingController();
  final TextEditingController _monthlyContributionController =
      TextEditingController();

  bool isLoading = false;
  String errorMessage = '';
  bool createGroup = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          _buildRegistrationForm(context),
          if (isLoading) Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 80),
          Icon(
            Icons.account_circle,
            size: 80,
            color: Colors.grey[700],
          ),
          SizedBox(height: 20),
          Text(
            'Admin Registration',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),

          // Name, Phone, Email, Password fields
          _buildTextField(_nameController, 'Full Name', Icons.person_outline),
          SizedBox(height: 20),
          _buildTextField(_phoneController, 'Phone Number', Icons.phone),
          SizedBox(height: 20),
          _buildTextField(
              _emailController, 'Email Address', Icons.email_outlined),
          SizedBox(height: 20),
          _buildTextField(_passwordController, 'Password', Icons.lock_outline,
              obscureText: true),
          SizedBox(height: 40),
          // In your _buildRegistrationForm method, add the invitation code field
          _buildTextField(
              _invitationCodeController, 'Invitation Code', Icons.vpn_key),

          // Checkbox for Group creation option
          CheckboxListTile(
            title: Text('Create a Group Now'),
            value: createGroup,
            onChanged: (bool? value) {
              setState(() {
                createGroup = value ?? false;
              });
            },
          ),
          if (createGroup) ...[
            _buildTextField(_groupNameController, 'Group Name', Icons.group),
            SizedBox(height: 20),
            _buildTextField(
                _seedMoneyController, 'Seed Money (MWK)', Icons.money),
            SizedBox(height: 20),
            _buildTextField(
                _interestRateController, 'Interest Rate (%)', Icons.percent),
            SizedBox(height: 20),
            _buildTextField(_monthlyContributionController,
                'Monthly Contribution (MWK)', Icons.attach_money),
            SizedBox(height: 40),
          ],

          // Register Button
          ElevatedButton(
            onPressed: _registerAdmin,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Register',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),

          // Error Message
          if (errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                errorMessage,
                style: TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  void _registerAdmin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    String invitationCode =
        _invitationCodeController.text.trim(); // Get the invitation code

    if (email.isEmpty ||
        password.isEmpty ||
        name.isEmpty ||
        phone.isEmpty ||
        invitationCode.isEmpty) {
      setState(() {
        errorMessage =
            'Please fill all required fields, including the invitation code.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Validate invitation code
      QuerySnapshot snapshot = await _db
          .collection('invitationCodes')
          .where('code', isEqualTo: invitationCode)
          .where('used', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          errorMessage = 'Invalid or used invitation code. Please try again.';
          isLoading = false;
        });
        return;
      }

      // Proceed with registration
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Default Material Icon DP (Flutter Icons)
        String defaultIcon =
            'account_circle'; // Store the material icon as a string

        // Save admin details in Firestore (in 'users' collection)
        await _db.collection('users').doc(user.uid).set({
          'userId': user.uid, // Ensure the user ID is stored
          'name': name,
          'email': email,
          'phone': phone,
          'role': 'admin', // Ensure the role is admin
          'profilePicture':
              defaultIcon, // Store the icon name as the profile picture
          'createdAt': Timestamp.now(),
        });

        // Mark invitation code as used
        await _db
            .collection('invitationCodes')
            .doc(snapshot.docs[0]
                .id) // Get the document ID of the matched invitation code
            .update({'used': true});

        // If "Create Group" option is selected
        if (createGroup) {
          await _createGroup(user.uid, name, phone, email);
        }

        // Navigate to Admin Dashboard after successful registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminDashboard(
              isAdmin: true,
              groupName: createGroup
                  ? _groupNameController.text.trim()
                  : 'Admin Group',
              isAdminView: true,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = _getErrorMessage(e);
        isLoading = false;
      });
    }
  }

  Future<void> _createGroup(
      String adminId, String name, String phone, String email) async {
    String groupName = _groupNameController.text.trim();
    double seedMoney = double.tryParse(_seedMoneyController.text.trim()) ?? 0.0;
    double interestRate =
        double.tryParse(_interestRateController.text.trim()) ?? 0.0;
    double monthlyContribution =
        double.tryParse(_monthlyContributionController.text.trim()) ?? 0.0;

    // Create the group and get the group ID
    DocumentReference groupRef = await _db.collection('groups').add({
      'groupName': groupName,
      'admin': adminId,
      'seedMoney': seedMoney,
      'interestRate': interestRate,
      'fixedAmount': monthlyContribution,
      'createdAt': Timestamp.now(),
    });

    // Add the admin as a member of the group using the 'members' array in the same document
    await groupRef.update({
      'members': FieldValue.arrayUnion([
        {
          'userId': adminId,
          'name': name,
          'contact': phone,
          'email': email,
          'role': 'admin', // Mark the role as 'admin'
          'profilePicture':
              'account_circle', // Use Material icon for the profile picture
        }
      ]),
    });
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
