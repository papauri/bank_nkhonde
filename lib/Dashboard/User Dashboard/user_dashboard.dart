import 'package:bank_nkhonde/Login%20Page/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Admin Dashboard/admin_dashboard.dart';
import 'profile_section.dart';
import 'group_section.dart';
import 'my_groups_tab.dart';  // Import MyGroupsTab

class UserDashboard extends StatefulWidget {
  final bool isAdmin; // Track if the user is an admin

  UserDashboard({this.isAdmin = false}); // Default is false

  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  int _selectedIndex = 0;

  // Track the selected tab index and dynamically render content below the dashboard
  static const List<String> _tabTitles = <String>[
    'My Groups',
    'Group Chat',
    'Notifications',
  ];

  // Handle tab selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      if (index == 3) {
        // Logout when clicking the logout tab
        FirebaseAuth.instance.signOut();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: GestureDetector(
        onTap: () {
          // If clicking outside the area, any open expansion tile will close
        },
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(), // Single bottom navigation bar
    );
  }

  // AppBar
  AppBar _buildAppBar() {
    return AppBar(
      title: Text('Dashboard', style: TextStyle(color: Colors.black)),
      backgroundColor: Colors.white,
      elevation: 0,
    );
  }

  // Body of the dashboard
  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              _buildProfileAndWelcomeSection(),
              SizedBox(height: 20),
              _buildGroupsExplanation(),
              SizedBox(height: 10),
              _buildGroupsSection(),
              SizedBox(height: 20),
              _buildDynamicContent(),  // Dynamic content depending on selected tab
            ],
          ),
        ),
      ],
    );
  }

  // Dynamic content based on the selected tab (My Groups or Group Chat)
  Widget _buildDynamicContent() {
    if (_selectedIndex == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Here you will find all the groups you are part of. Tap to see the group members.',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          SizedBox(height: 10),
          MyGroupsTab(currentUserId: currentUserId),  // Show My Groups section
        ],
      );
    } else if (_selectedIndex == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Chat will appear here.',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          // Placeholder for Group Chat. You can replace this with actual chat content.
          Container(
            margin: EdgeInsets.only(top: 10),
            padding: EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Text(
              'This is where the group chat will be displayed. Add actual chat UI here.',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      );
    } else {
      return Center(child: Text('Notifications will appear here.'));
    }
  }

  Widget _buildProfileAndWelcomeSection() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(currentUserId).get(),
      builder: (context, snapshot) {
        String userName = 'User';
        String? profilePictureUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          userName = snapshot.data!.get('name') ?? 'User';
          profilePictureUrl = snapshot.data!.get('profilePicture');
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ProfileSection(profilePictureUrl: profilePictureUrl),  // Pass profile picture URL
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $userName!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Explore the groups you’re part of below.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupsExplanation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Groups',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Below are the groups you are a member of. Tap on any group to view more details.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsSection() {
    return GroupSection(currentUserId: currentUserId);  // The main groups display
  }

// Bottom Navigation Bar for Quick Actions
BottomNavigationBar _buildBottomNavigationBar() {
  List<BottomNavigationBarItem> items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.group),
      label: 'My Groups',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.message),
      label: 'Group Chat',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.notifications),
      label: 'Notifications',
    ),
  ];

  // Add Admin View between Group Chat and Notifications if the user is an admin
  if (widget.isAdmin) {
    items.insert(2, BottomNavigationBarItem(
      icon: Icon(Icons.admin_panel_settings),
      label: 'Admin View',
    ));
  }

  // Add Logout as the last item
  items.add(
    BottomNavigationBarItem(
      icon: Icon(Icons.logout),
      label: 'Logout',
    ),
  );

  return BottomNavigationBar(
    type: BottomNavigationBarType.fixed,  // Ensure labels are always visible
    items: items,
    currentIndex: _selectedIndex,
    selectedItemColor: Colors.blue,  // Highlight only selected tab
    unselectedItemColor: Colors.grey,  // Grey out unselected items
    showUnselectedLabels: true,  // Ensure all labels are visible even when not selected
    onTap: (index) {
      // Handle Logout and Switch to Admin View
      if (index == items.length - 1) { // Logout is always the last item
        FirebaseAuth.instance.signOut();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else if (index == 2 && widget.isAdmin) {
        // Switch back to Admin View
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminDashboard(
              isAdmin: true, 
              groupName: '', 
              isAdminView: true,  // Ensure the admin view is passed
            ),
          ),
        );  // Navigate back to the Admin Dashboard with pushReplacement
      } else {
        setState(() {
          _selectedIndex = index;
        });
      }
    },
  );
}
}
