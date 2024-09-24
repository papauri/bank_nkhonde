import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemberManagementPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  MemberManagementPage({required this.groupId, required this.groupName});

  @override
  _MemberManagementPageState createState() => _MemberManagementPageState();
}

class _MemberManagementPageState extends State<MemberManagementPage> {
  final TextEditingController _memberNameController = TextEditingController();
  final TextEditingController _memberContactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String errorMessage = '';
  bool isAdmin = false; // Track whether the new member should be an admin
  String? selectedGroupId; // To track the selected group for editing

  // Separate controllers for edit dialog
  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editContactController = TextEditingController();
  final TextEditingController _editEmailController = TextEditingController(); // Edit email controller
  bool isEditingAdmin = false;

  Future<void> _refreshMembers() async {
    setState(() {}); // Trigger a refresh for member list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Members - ${widget.groupName}'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMembers,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final groupData = snapshot.data?.data() as Map<String, dynamic>?;

                  final members = groupData?['members'] ?? [];

                  if (members.isEmpty) {
                    return Center(child: Text('No members in this group.'));
                  }

                  return ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return ListTile(
                        title: Text(member['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Contact: ${member['contact']}'),
                            Text('Email: ${member['email'] ?? "No Email"}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                _showEditMemberDialog(member);
                              },
                              tooltip: 'Edit Member',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                _deleteMember(member['userId'], member);
                              },
                              tooltip: 'Delete Member',
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                    controller: _memberNameController,
                    decoration: InputDecoration(
                      labelText: 'Member Name',
                    ),
                  ),
                  TextField(
                    controller: _memberContactController,
                    decoration: InputDecoration(
                      labelText: 'Member Contact',
                    ),
                  ),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                    ),
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                    ),
                    obscureText: true, // For obscuring password text
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Admin"),
                      Switch(
                        value: isAdmin,
                        onChanged: (value) {
                          setState(() {
                            isAdmin = value;
                          });
                        },
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _addMember,
                    child: Text('Add Member'),
                  ),
                  if (errorMessage.isNotEmpty)
                    Text(
                      errorMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to add a new member
  void _addMember() async {
    String memberName = _memberNameController.text.trim();
    String memberContact = _memberContactController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (memberName.isEmpty || memberContact.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Please fill in all fields.';
      });
      return;
    }

    // Check if email is already in use
    var existingUser = await _checkIfEmailExists(email);
    if (existingUser != null) {
      setState(() {
        errorMessage = 'Email is already in use by another account.';
      });
      return;
    }

    try {
      // Add member using FirebaseAuth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Add member to the 'members' array of the group document in Firestore
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .update({
          'members': FieldValue.arrayUnion([{
            'name': memberName,
            'contact': memberContact,
            'email': email,
            'userId': user.uid,
          }])
        });

        // Set user information and role in Firestore 'users' collection
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': memberName,
          'contact': memberContact,
          'email': email,
          'role': isAdmin ? 'admin' : 'user',  // Assign the role
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Member added successfully!')),
        );

        _memberNameController.clear();
        _memberContactController.clear();
        _emailController.clear();
        _passwordController.clear();
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to add member. Try again.';
      });
    }
  }

  // Show the edit member dialog box
  void _showEditMemberDialog(Map<String, dynamic> member) {
    _editNameController.text = member['name'];
    _editContactController.text = member['contact'];
    _editEmailController.text = member['email'] ?? ''; // Ensure email is pre-filled
    isEditingAdmin = (member['role'] == 'admin');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _editNameController,
                decoration: InputDecoration(labelText: 'Member Name'),
              ),
              TextField(
                controller: _editContactController,
                decoration: InputDecoration(labelText: 'Member Contact'),
              ),
              TextField(
                controller: _editEmailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Admin"),
                  Switch(
                    value: isEditingAdmin,
                    onChanged: (value) {
                      setState(() {
                        isEditingAdmin = value;
                      });
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  "Warning: Changing user details like email or group may affect records.",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateMember(member['userId'], member);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Function to update member without duplication
  void _updateMember(String userId, Map<String, dynamic> oldMember) async {
    String name = _editNameController.text.trim();
    String contact = _editContactController.text.trim();
    String email = _editEmailController.text.trim();

    if (name.isEmpty || contact.isEmpty || email.isEmpty) {
      setState(() {
        errorMessage = 'Please fill in all fields.';
      });
      return;
    }

    // If email is changed, check if the new email is already in use
    if (email != oldMember['email']) {
      var existingUser = await _checkIfEmailExists(email);
      if (existingUser != null) {
        setState(() {
          errorMessage = 'Email is already in use by another account.';
        });
        return;
      }
    }

    try {
      // Remove the old member details
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
        'members': FieldValue.arrayRemove([oldMember]), // Remove the old record
      });

      // Add the updated member details
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
        'members': FieldValue.arrayUnion([{
          'name': name,
          'contact': contact,
          'email': email,
          'userId': userId,
        }])
      });

      // Update the user in 'users' collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'name': name,
        'contact': contact,
        'email': email,
        'role': isEditingAdmin ? 'admin' : 'user',  // Update the role
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member updated successfully!')),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to update member. Try again.';
      });
    }
  }

  // Function to delete a member
  void _deleteMember(String userId, Map<String, dynamic> member) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
        'members': FieldValue.arrayRemove([member]), // Remove the member
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member deleted successfully!')),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to delete member. Try again.';
      });
    }
  }

  // Check if an email already exists
  Future<User?> _checkIfEmailExists(String email) async {
    try {
      final list = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (list.isNotEmpty) {
        return FirebaseAuth.instance.currentUser;
      }
    } catch (e) {
      print('Error checking email existence: $e');
    }
    return null;
  }
}
