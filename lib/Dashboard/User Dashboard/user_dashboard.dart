import 'package:bank_nkhonde/Landing%20Page/login_page.dart';
import 'package:flutter/material.dart';
import 'profile_section.dart';
import 'group_section.dart';
import 'quick_actions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDashboard extends StatelessWidget {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        children: [
          ProfileSection(),
          GroupSection(currentUserId: currentUserId),  // Group Section
          QuickActions(),
        ],
      ),
    );
  }
}
