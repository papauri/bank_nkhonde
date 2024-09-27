import 'package:flutter/material.dart';
import 'member_service.dart';

class AddMemberForm extends StatefulWidget {
  final String groupId;

  AddMemberForm({required this.groupId});

  @override
  _AddMemberFormState createState() => _AddMemberFormState();
}

class _AddMemberFormState extends State<AddMemberForm> {
  final TextEditingController _memberNameController = TextEditingController();
  final TextEditingController _memberContactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isAdmin = false;
  String errorMessage = '';

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
      await MemberService.addMember(
        groupId: widget.groupId,
        memberName: memberName,
        memberContact: memberContact,
        email: email,
        password: password,
        isAdmin: isAdmin,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member added successfully!')),
      );

      _memberNameController.clear();
      _memberContactController.clear();
      _emailController.clear();
      _passwordController.clear();
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to add member. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _memberNameController,
          decoration: InputDecoration(labelText: 'Member Name'),
        ),
        TextField(
          controller: _memberContactController,
          decoration: InputDecoration(labelText: 'Member Contact'),
        ),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(labelText: 'Password'),
          obscureText: true,
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
    );
  }
}
