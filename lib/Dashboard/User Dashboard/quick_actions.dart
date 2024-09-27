import 'package:bank_nkhonde/Login%20Page/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildQuickActionTile(
          context: context,
          icon: Icons.group,
          label: 'View My Groups',
          onPressed: () {
            // Implement view groups functionality
          },
        ),
        SizedBox(height: 12),
        _buildQuickActionTile(
          context: context,
          icon: Icons.message,
          label: 'Group Chat',
          onPressed: () {
            // Implement group chat functionality
          },
        ),
        SizedBox(height: 12),
        _buildQuickActionTile(
          context: context,
          icon: Icons.notifications,
          label: 'Notifications',
          onPressed: () {
            // Implement notifications functionality
          },
        ),
        SizedBox(height: 12),
        _buildQuickActionTile(
          context: context,
          icon: Icons.logout,
          label: 'Logout',
          onPressed: () {
            FirebaseAuth.instance.signOut();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 3,
              blurRadius: 6,
              offset: Offset(0, 3), // shadow position
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, size: 30, color: Colors.blueGrey),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
