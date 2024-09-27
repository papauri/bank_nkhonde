import 'package:bank_nkhonde/Group%20Management/GroupOverviewPage.dart';
import 'package:bank_nkhonde/Group%20Management/group_creation.dart';
import 'package:bank_nkhonde/Dashboard/User%20Dashboard/user_dashboard.dart';
import 'package:bank_nkhonde/Login%20Page/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String currentGroupId = '';
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
          title: Text('Admin Dashboard'),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 1,
          foregroundColor: Colors.black,
        ),
        body: RefreshIndicator(
          onRefresh: _refreshGroups,
          child: isAdminView ? _buildAdminBody() : UserDashboard(),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildAdminBody() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildHeaderSection(),
          _buildGroupList(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      // Removed the explicit background color to let it blend into the background
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

  Widget _buildGroupList() {
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
          return Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                'You have not created any groups yet.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final groupId = group.id;
            final groupName = group['groupName'];
            final seedMoney = group['seedMoney'];
            final interestRate = group['interestRate'];
            final fixedAmount = group['fixedAmount'];

            return _buildGroupCard(
              groupId: groupId,
              groupName: groupName,
              seedMoney: seedMoney,
              interestRate: interestRate,
              fixedAmount: fixedAmount,
            );
          },
        );
      },
    );
  }

  Widget _buildGroupCard({
    required String groupId,
    required String groupName,
    required double seedMoney,
    required double interestRate,
    required double fixedAmount,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.black,
          child: Icon(Icons.group, color: Colors.white),
        ),
        title: Text(
          groupName,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text('Seed Money: MWK $seedMoney'),
            Text('Interest Rate: $interestRate%'),
            Text('Monthly Contribution: MWK $fixedAmount'),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.black),
        onTap: () {
          setState(() {
            currentGroupId = groupId;
          });
          _showGroupOverview(context, groupId, groupName);
        },
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
            setState(() {
              isAdminView = !isAdminView;
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
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
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
}
