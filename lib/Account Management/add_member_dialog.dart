import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:url_launcher/url_launcher.dart'; // Import the url_launcher package

class AddMemberDialog extends StatefulWidget {
  final String groupId;
  final String whatsappGroupInviteLink;  // WhatsApp group invite link

  AddMemberDialog({required this.groupId, required this.whatsappGroupInviteLink});

  @override
  _AddMemberDialogState createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(); // Password field
  String phoneNumber = '';  // Store the phone number with country code
  bool isAdmin = false;
  String errorMessage = '';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add new member function
  void _addMember() async {
    if (_nameController.text.isEmpty || phoneNumber.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        errorMessage = 'Please fill all fields, including password.';
      });
      return;
    }

    try {
      // Create the user in Firebase Authentication with the provided password
      User? newUser = (await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),  // Use admin-provided password
      )).user;

      if (newUser != null) {
        // Save the user in the users collection (Firestore)
        await _db.collection('users').doc(newUser.uid).set({
          'userId': newUser.uid,
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': phoneNumber,
          'role': isAdmin ? 'admin' : 'member',
          'profilePicture': 'account_circle',  // Default Material Icon for DP
          'createdAt': Timestamp.now(),
        });

        // Add the user to the group in Firestore
        await _db.collection('groups').doc(widget.groupId).update({
          'members': FieldValue.arrayUnion([
            {
              'userId': newUser.uid,
              'name': _nameController.text,
              'contact': phoneNumber,
              'email': _emailController.text,
              'role': isAdmin ? 'admin' : 'member',
              'profilePicture': 'account_circle',  // Material Icon for DP
            }
          ]),
        });

        // Send WhatsApp invite link to the new member
        _sendWhatsAppInvite(phoneNumber, widget.whatsappGroupInviteLink);

        Navigator.of(context).pop(); // Close dialog on success

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Member added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error adding member: ${e.toString()}';
      });
    }
  }

  // Function to send WhatsApp invite using the phone number
  void _sendWhatsAppInvite(String phoneNumber, String groupInviteLink) async {
    final Uri whatsappUrl = Uri.parse('https://wa.me/$phoneNumber?text=Join our WhatsApp group using this link: $groupInviteLink');

    // Launch the WhatsApp link
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      throw 'Could not launch WhatsApp';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Close button (X)
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.black),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
              ),
            ),
            
            // Title
            Center(
              child: Text(
                'Add New Member',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Name Input
            _buildInputField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline,
            ),
            SizedBox(height: 16),

            // Phone Number Input with Country Code and Flag
            IntlPhoneField(
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              initialCountryCode: 'MW',  // Default country code
              onChanged: (phone) {
                phoneNumber = phone.completeNumber;  // Store the full number
              },
            ),
            SizedBox(height: 16),

            // Email Input
            _buildInputField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
            ),
            SizedBox(height: 16),

            // Password Input
            _buildInputField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: true,  // Hide password text
            ),
            SizedBox(height: 16),

            // Admin Switch
            SwitchListTile(
              title: Text(
                isAdmin ? 'Admin (Elevated Privileges)' : 'Regular Member',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              value: isAdmin,
              activeColor: Colors.black,
              onChanged: (bool value) {
                setState(() {
                  isAdmin = value;
                });
              },
              secondary: Icon(
                isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
                color: isAdmin ? Colors.black : Colors.grey,
                size: 28,
              ),
            ),
            SizedBox(height: 16),

            // Error Message
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Center(
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ),

            // Add Member Button
            ElevatedButton(
              onPressed: _addMember,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Black button for consistency
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Add Member',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to create input fields with icons
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black), // Black icons for minimal look
        filled: true,
        fillColor: Colors.grey[100], // Light grey background for input fields
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }
}
