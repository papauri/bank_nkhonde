import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_member_by_admin.dart';
import 'edit_member_by_admin.dart';
import 'member_service.dart';

class MemberManagementPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  MemberManagementPage({required this.groupId, required this.groupName});

  @override
  _MemberManagementPageState createState() => _MemberManagementPageState();
}

class _MemberManagementPageState extends State<MemberManagementPage> {
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
                                EditMemberDialog.show(context, member, widget.groupId);
                              },
                              tooltip: 'Edit Member',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                MemberService.deleteMember(member['userId'], member, widget.groupId);
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
              child: AddMemberForm(groupId: widget.groupId),
            ),
          ],
        ),
      ),
    );
  }
}
