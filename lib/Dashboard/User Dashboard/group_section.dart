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
          return Center(child: Text('You are not part of any groups.'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final groupName = group['groupName'];
            final groupId = group.id;
            final fixedAmount = group['fixedAmount'];
            final seedMoney = group['seedMoney'];

            return Card(
              margin: EdgeInsets.all(10),
              child: ListTile(
                title: Text(groupName, style: TextStyle(fontSize: 18)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fixed Contribution: MWK $fixedAmount'),
                    Text('Seed Money: MWK $seedMoney'),
                  ],
                ),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          GroupDetailsPage(groupId: groupId, groupName: groupName),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
