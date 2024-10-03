import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_group_overview.dart';

class AdminGroupList extends StatelessWidget {
  const AdminGroupList({Key? key}) : super(key: key);

  void _showGroupOverview(BuildContext context, String groupId, String groupName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupOverviewPage(groupId: groupId, groupName: groupName),
      ),
    );
  }

  Future<double> _fetchPendingPayments(String groupId) async {
    // Fetch pending payments data from Firestore
    final paymentsSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('payments')
        .where('status', isEqualTo: 'pending')
        .get();

    double totalPending = 0.0;
    for (var doc in paymentsSnapshot.docs) {
      totalPending += (doc['amount'] as num).toDouble();
    }
    return totalPending;
  }

  @override
  Widget build(BuildContext context) {
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
            final createdDate = (group['createdAt'] as Timestamp).toDate();
            final members = group['members'] as List<dynamic>;

            return FutureBuilder<double>(
              future: _fetchPendingPayments(groupId),
              builder: (context, pendingSnapshot) {
                if (!pendingSnapshot.hasData) {
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Text('Loading payments...'),
                    ),
                  );
                }

                final pendingPayments = pendingSnapshot.data!;
                final bool hasPending = pendingPayments > 0;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: hasPending ? Colors.redAccent : Colors.green,
                      child: Icon(
                        hasPending ? Icons.warning_amber_rounded : Icons.group,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      groupName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.people_outline, size: 18, color: Colors.grey),
                            SizedBox(width: 5),
                            Text('${members.length} members', style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                            SizedBox(width: 5),
                            Text(
                              'Created on: ${createdDate.day}/${createdDate.month}/${createdDate.year}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        if (pendingPayments > 0) ...[
                          Row(
                            children: [
                              Icon(Icons.payment, size: 18, color: Colors.redAccent),
                              SizedBox(width: 5),
                              Text(
                                'Pending Payments: MWK $pendingPayments',
                                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.black54),
                    onTap: () {
                      _showGroupOverview(context, groupId, groupName);
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
