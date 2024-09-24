import 'package:flutter/material.dart';
import 'member_service.dart';

class EditMemberDialog {
  static void show(BuildContext context, Map<String, dynamic> member, String groupId) {
    final TextEditingController _editNameController = TextEditingController(text: member['name']);
    final TextEditingController _editContactController = TextEditingController(text: member['contact']);
    final TextEditingController _editEmailController = TextEditingController(text: member['email']);
    bool isEditingAdmin = member['role'] == 'admin';

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
                      isEditingAdmin = value;
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
                MemberService.updateMember(
                  memberId: member['userId'],
                  groupId: groupId,
                  newName: _editNameController.text.trim(),
                  newContact: _editContactController.text.trim(),
                  newEmail: _editEmailController.text.trim(),
                  newRole: isEditingAdmin ? 'admin' : 'user',
                  oldMember: member,
                );
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
