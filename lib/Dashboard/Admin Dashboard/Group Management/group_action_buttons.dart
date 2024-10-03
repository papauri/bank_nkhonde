import 'package:flutter/material.dart';

class GroupActionButtons extends StatelessWidget {
  final Function onViewMembers;
  final Function onManageLoans;
  final Function onManagePayments;
  final Function onEditGroupSettings;  // Add this

  const GroupActionButtons({
    required this.onViewMembers,
    required this.onManageLoans,
    required this.onManagePayments,
    required this.onEditGroupSettings,  // Add this
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildActionButton('View Members', Icons.group, onViewMembers),
          _buildActionButton('Manage Loans', Icons.monetization_on, onManageLoans),
          _buildActionButton('Manage Payments', Icons.payment, onManagePayments),
          SizedBox(height: 16),  // Add spacing
          _buildActionButton('Edit Group Settings', Icons.settings, onEditGroupSettings),  // Add Edit Group Settings button
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Function onPressed) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 6),
      child: OutlinedButton.icon(
        onPressed: () => onPressed(),
        icon: Icon(icon, color: Colors.black),
        label: Text(label, style: TextStyle(color: Colors.black)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.black),
          padding: EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
