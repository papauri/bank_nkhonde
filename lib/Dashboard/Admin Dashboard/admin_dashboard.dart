import 'package:bank_nkhonde/Dashboard/Admin%20Dashboard/Group%20Management/admin_create_group.dart';
import 'package:bank_nkhonde/Dashboard/User%20Dashboard/user_dashboard.dart';
import 'package:bank_nkhonde/Login%20Page/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Group Management/admin_group_list.dart'; // Import the new admin group list file

class AdminDashboard extends StatefulWidget {
  final bool isAdmin;
  final String groupName;
  final bool isAdminView;

  AdminDashboard({
    required this.isAdmin,
    required this.groupName,
    this.isAdminView = true,
  });

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool isAdminView = true;
  String userName = 'Admin';

  @override
  void initState() {
    super.initState();
    isAdminView = widget.isAdminView;
    _getUserName();
  }

  Future<void> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc.data()?['name'] ?? 'Admin';
        });
      }
    }
  }

  Future<void> _refreshGroups() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAdminView ? 'Admin Dashboard' : 'User Dashboard'),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 1,
          foregroundColor: Colors.black,
        ),
        body: RefreshIndicator(
          onRefresh: _refreshGroups,
          child: isAdminView
              ? _buildAdminBody()
              : UserDashboard(isAdmin: widget.isAdmin), // Pass isAdmin to UserDashboard
        ),
        bottomNavigationBar: isAdminView
            ? _buildBottomNavigationBar() // Only show Admin BottomNavigationBar in admin view
            : null, // Remove BottomNavigationBar when in user view
      ),
    );
  }

  Widget _buildAdminBody() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildHeaderSection(),
          AdminGroupList(), // Use the separated AdminGroupList widget
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        children: [
          Icon(
            Icons.admin_panel_settings,
            size: 60,
            color: Colors.black,
          ),
          SizedBox(height: 10),
          Text(
            'Welcome, $userName',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Here are your groups:',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.logout),
          label: 'Logout',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            isAdminView ? Icons.person : Icons.admin_panel_settings,
          ),
          label: isAdminView ? 'User View' : 'Admin View',
        ),
        if (isAdminView) // Create Group button only appears in admin view
          BottomNavigationBarItem(
            icon: Icon(Icons.group_add),
            label: 'Create Group',
          ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            FirebaseAuth.instance.signOut();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginPage()),
              (Route<dynamic> route) => false,
            );
            break;
          case 1:
            if (isAdminView) {
              // Switching from Admin to User View
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => UserDashboard(isAdmin: true),
                ),
              );
            } else {
              // Switching from User to Admin View
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminDashboard(
                    isAdmin: true,
                    groupName: widget.groupName,
                    isAdminView: true,
                  ),
                ),
              );
            }
            break;
          case 2:
            if (isAdminView) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GroupCreationPage()),
              );
            }
            break;
        }
      },
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
    );
  }
}
