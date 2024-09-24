import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupMembersPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  GroupMembersPage({required this.groupId, required this.groupName});

  @override
  _GroupMembersPageState createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends State<GroupMembersPage> {
  final TextEditingController _memberNameController = TextEditingController();
  final TextEditingController _memberContactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String errorMessage = '';
  String? selectedGroupId; // To track the selected group for editing

  Future<void> _refreshMembers() async {
    setState(() {}); // Refresh member list
  }

  Future<List<QueryDocumentSnapshot>> _fetchAvailableGroups() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('groups').get();
    return querySnapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group: ${widget.groupName}'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMembers,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .collection('members')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final members = snapshot.data!.docs;

                  if (members.isEmpty) {
                    return Center(child: Text('No members in this group.'));
                  }

                  return ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return ListTile(
                        title: Text(member['name']),
                        subtitle: Text('Contact: ${member['contact']}'),
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
                                _deleteMember(member.id);
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
                    obscureText: true, // Correct use of obscureText
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

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .update({
          'members': FieldValue.arrayUnion([{
            'name': memberName,
            'contact': memberContact,
            'userId': user.uid,
          }])
        });

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': memberName,
          'contact': memberContact,
          'email': email,
          'role': 'user', // Set the default role as 'user'
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

  void _showEditMemberDialog(QueryDocumentSnapshot member) async {
    _memberNameController.text = member['name'];
    _memberContactController.text = member['contact'];

    // Fetch the list of available groups for the dropdown
    List<QueryDocumentSnapshot> availableGroups = await _fetchAvailableGroups();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _memberNameController,
                decoration: InputDecoration(labelText: 'Member Name'),
              ),
              TextField(
                controller: _memberContactController,
                decoration: InputDecoration(labelText: 'Member Contact'),
              ),
              // Dropdown to select a group
              DropdownButtonFormField<String>(
                value: selectedGroupId ?? widget.groupId,  // Set the default value to current groupId
                decoration: InputDecoration(labelText: 'Group'),
                items: availableGroups.map((group) {
                  return DropdownMenuItem<String>(
                    value: group.id,
                    child: Text(group['groupName']),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedGroupId = newValue;
                  });
                },
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
                _updateMember(member.id);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _updateMember(String memberId) async {
    String name = _memberNameController.text.trim();
    String contact = _memberContactController.text.trim();

    if (name.isEmpty || contact.isEmpty) {
      setState(() {
        errorMessage = 'Please fill in all fields.';
      });
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('members')
          .doc(memberId)
          .update({
        'name': name,
        'contact': contact,
      });

      // If the group is changed, update the group collection
      if (selectedGroupId != null && selectedGroupId != widget.groupId) {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .update({
          'members': FieldValue.arrayRemove([{
            'name': name,
            'contact': contact,
            'userId': memberId,
          }]),
        });

        await FirebaseFirestore.instance
            .collection('groups')
            .doc(selectedGroupId)
            .update({
          'members': FieldValue.arrayUnion([{
            'name': name,
            'contact': contact,
            'userId': memberId,
          }]),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member updated successfully!')),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to update member. Try again.';
      });
    }
  }

  void _deleteMember(String memberId) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('members')
          .doc(memberId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member deleted successfully!')),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to delete member. Try again.';
      });
    }
  }
}
