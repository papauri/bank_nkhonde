import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'group_details_page.dart';

class GroupSection extends StatelessWidget {
  final String? currentUserId;

  GroupSection({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('groups').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final groups = snapshot.data!.docs.where((group) {
          final members = group['members'] as List<dynamic>;
          return members.any((member) => member['userId'] == currentUserId);
        }).toList();

        if (groups.isEmpty) {
          return Center(
            child: Text(
              'You are not part of any groups.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: BouncingScrollPhysics(),  // Smooth scrolling
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final groupName = group['groupName'];
            final groupId = group.id;
            final fixedAmount = group['fixedAmount'];
            final seedMoney = group['seedMoney'];

            return _buildGroupCard(context, groupId, groupName, fixedAmount, seedMoney);
          },
        );
      },
    );
  }

  Widget _buildGroupCard(BuildContext context, String groupId, String groupName, dynamic fixedAmount, dynamic seedMoney) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),  // Adequate padding
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailsPage(groupId: groupId, groupName: groupName),
            ),
          );
        },
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.group,
                      size: 32,
                      color: Colors.blueGrey,  // Group icon for visual aid
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        groupName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,  // Prevents overflow with long names
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _buildGroupDetailsRow(
                  label: 'Fixed Contribution:',
                  value: 'MWK $fixedAmount',
                  icon: Icons.monetization_on,
                ),
                _buildGroupDetailsRow(
                  label: 'Seed Money:',
                  value: 'MWK $seedMoney',
                  icon: Icons.savings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupDetailsRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }
}
