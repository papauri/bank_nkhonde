import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_member_dialog.dart';
import 'edit_member_dialog.dart'; // Import the modal dialog widget
import 'dart:async';

class MemberManagementPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  MemberManagementPage({required this.groupId, required this.groupName});

  @override
  _MemberManagementPageState createState() => _MemberManagementPageState();
}

class _MemberManagementPageState extends State<MemberManagementPage> {
  String? currentUserId;
  bool _showAddMemberHint = true;  // To control the visibility of the flashing effect

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Flash the "Add Member" icon for 5 seconds
    Timer(Duration(seconds: 5), () {
      setState(() {
        _showAddMemberHint = false;
      });
    });
  }

  Future<void> _refreshMembers() async {
    setState(() {}); // Trigger a refresh for the member list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // White background for app bar
        elevation: 0, // No shadow
        title: Text(
          'Manage Members',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black, // Black text for visibility
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),  // Black icon for back button
      ),
      body: Stack(
        children: [
          Positioned.fill(
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
                          bool isAdmin = member['role'] == 'admin';
                          bool isCurrentUser = member['userId'] == currentUserId;

                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            title: Text(
                              member['name'],
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Contact: ${member['contact']}'),
                                Text('Email: ${member['email'] ?? "No Email"}'),
                                if (isAdmin) Text('(Admin)', style: TextStyle(color: Colors.redAccent)),
                              ],
                            ),
                            trailing: _buildActionButtons(member, isCurrentUser),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Flashing Add Member Icon
          Positioned(
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                _showAddMemberDialog(context);  // Open the Add Member dialog
              },
              child: Column(
                children: [
                  AnimatedOpacity(
                    opacity: _showAddMemberHint ? 0.5 : 1.0, // Flashing effect
                    duration: Duration(milliseconds: 500),
                    child: Icon(
                      Icons.person_add_alt_1, // Minimalistic style icon
                      color: Colors.black, // Black and white style for the icon
                      size: 36,
                    ),
                  ),
                  if (_showAddMemberHint)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Add Member',
                        style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to show the dialog box for adding a new member
  void _showAddMemberDialog(BuildContext context) {
    String groupInviteLink = 'https://chat.whatsapp.com/your-invite-link'; // Replace with your actual WhatsApp group invite link

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddMemberDialog(
          groupId: widget.groupId,
          whatsappGroupInviteLink: groupInviteLink, // Pass the WhatsApp group invite link here
        );
      },
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> member, bool isCurrentUser) {
    final bool isLoggedInAdmin = member['userId'] == currentUserId;

    // Admin cannot edit their own account, only show "(You)" indicator
    if (isLoggedInAdmin) {
      return Text('(You)', style: TextStyle(color: Colors.green));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit_outlined, color: Colors.black), // Minimalistic edit icon
          onPressed: () {
            // Trigger the EditMemberDialog
            EditMemberDialog.show(
              context,
              member,
              widget.groupId,
            );
          },
          tooltip: 'Edit Member',
        ),
      ],
    );
  }
}
