import 'package:bank_nkhonde/Group%20Management/GroupOverviewPage.dart';
import 'package:bank_nkhonde/Group%20Management/group_creation.dart';
import 'package:bank_nkhonde/Account%20Management/member_management_page.dart'; // Import the separated GroupMembersPage
import 'package:bank_nkhonde/Dashboard/User%20Dashboard/user_dashboard.dart';
import 'package:bank_nkhonde/Login%20Page/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Loan Management/loan_management_page.dart';
import '../Loan Management/payment_management_page.dart';

class AdminDashboard extends StatefulWidget {
  final bool isAdmin;
  final String groupName;
  final bool isAdminView; // To switch between admin and user views

  AdminDashboard({
    required this.isAdmin,
    required this.groupName,
    this.isAdminView = true, // Default admin view is true for admins
  });

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool isAdminView = true; // Manage the toggle between admin and user views
  String currentGroupId = ''; // Track the groupId for use in navigation

  @override
  void initState() {
    super.initState();
    isAdminView = widget.isAdminView;
  }

  Future<void> _refreshGroups() async {
    setState(() {}); // Trigger UI update for group refresh
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAdminView ? 'Admin Dashboard' : 'User Dashboard'), // Dynamically set title
        ),
        body: RefreshIndicator(
          onRefresh: _refreshGroups,
          child: isAdminView
              ? _buildAdminBody() // Admin View
              : UserDashboard(), // Switch to User Dashboard when toggle is off
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.logout),
              label: 'Logout',
            ),
            BottomNavigationBarItem(
              icon: Icon(isAdminView
                  ? Icons.person // Icon for switching to User view
                  : Icons.admin_panel_settings), // Icon for switching to Admin view
              label: isAdminView ? 'Switch to User' : 'Switch to Admin',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
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
                setState(() {
                  isAdminView = !isAdminView; // Toggle between Admin and User views
                });
                break;
              case 2:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GroupCreationPage()),
                );
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildAdminBody() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('groups')
        .where('admin', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Center(child: CircularProgressIndicator());
      }

      final groups = snapshot.data!.docs;

      if (groups.isEmpty) {
        return Center(child: Text('No groups available.'));
      }

      return ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          final groupId = group.id;
          final groupName = group['groupName'];
          final seedMoney = group['seedMoney'];
          final interestRate = group['interestRate'];
          final fixedAmount = group['fixedAmount']; 

          return ListTile(
            title: Text(groupName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seed Money: MWK $seedMoney'),
                Text('Interest Rate: $interestRate%'),
                Text('Fixed Monthly Contribution: MWK $fixedAmount'),
              ],
            ),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              setState(() {
                currentGroupId = groupId;
              });
              _showGroupOverview(context, groupId, groupName);
            },
          );
        },
      );
    },
  );
}


  void _showGroupOverview(BuildContext context, String groupId, String groupName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupOverviewPage(groupId: groupId, groupName: groupName),
      ),
    );
  }

Widget _buildActionButtons(BuildContext context) {
  return Column(
    children: [
      ElevatedButton.icon(
        onPressed: () {
          if (currentGroupId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoanManagementPage(
                    groupId: currentGroupId, groupName: ''),
              ),
            );
          } else {
            _showNoGroupAlert();
          }
        },
        icon: Icon(Icons.monetization_on),
        label: Text('Manage Loans'),
      ),
      ElevatedButton.icon(
        onPressed: () {
          if (currentGroupId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentManagementPage(
                    groupId: currentGroupId, groupName: ''),
              ),
            );
          } else {
            _showNoGroupAlert();
          }
        },
        icon: Icon(Icons.payment),
        label: Text('Manage Payments'),
      ),
      ElevatedButton.icon(
        onPressed: () {
          if (currentGroupId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MemberManagementPage(
                    groupId: currentGroupId, groupName: widget.groupName),
              ),
            );
          } else {
            _showNoGroupAlert();
          }
        },
        icon: Icon(Icons.people),
        label: Text('Manage Members'),
      ),
    ],
  );
}


  void _showNoGroupAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('No group found. Please create or select a group first.')),
    );
  }
}