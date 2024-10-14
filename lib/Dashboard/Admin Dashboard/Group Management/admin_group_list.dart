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

  Future<int> _fetchPendingLoans(String groupId) async {
    // Fetch pending loans data from Firestore
    final loansSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('loans')
        .where('status', isEqualTo: 'pending')
        .get();

    return loansSnapshot.docs.length; // Return count of pending loans
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

            return FutureBuilder<int>(
              future: _fetchPendingLoans(groupId), // Fetch pending loans
              builder: (context, loanSnapshot) {
                return FutureBuilder<double>(
                  future: _fetchPendingPayments(groupId), // Fetch pending payments
                  builder: (context, pendingSnapshot) {
                    if (!pendingSnapshot.hasData || !loanSnapshot.hasData) {
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
                    final pendingLoans = loanSnapshot.data!;
                    final bool hasPendingLoans = pendingLoans > 0;
                    final bool hasPendingPayments = pendingPayments > 0;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: (hasPendingLoans || hasPendingPayments)
                                  ? Colors.redAccent
                                  : Colors.green,
                              child: Icon(
                                Icons.group,
                                color: Colors.white,
                              ),
                            ),
                            if (hasPendingLoans || hasPendingPayments) // Show notification badge
                              Positioned(
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${pendingLoans + (hasPendingPayments ? 1 : 0)}', // Combined count of loans and payments
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
                            // Simple note indicating what's pending
                            if (hasPendingLoans || hasPendingPayments)
                              Text(
                                hasPendingLoans && hasPendingPayments
                                    ? 'Pending loans and payments'
                                    : hasPendingLoans
                                        ? 'Pending loans'
                                        : 'Pending payments',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
      },
    );
  }
}
