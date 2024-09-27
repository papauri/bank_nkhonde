import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'payment_page.dart';

class ContributionPage extends StatelessWidget {
  final String groupId;

  ContributionPage({required this.groupId});

  @override
  Widget build(BuildContext context) {
    // Implement the contributions list and make contribution button
    return Scaffold(
      appBar: AppBar(
        title: Text('Contributions'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Display contributions
          Expanded(
            child: ContributionsList(groupId: groupId),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                // Navigate to make a contribution
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentPage(groupId: groupId),
                  ),
                );
              },
              child: Text('Make a Contribution'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContributionsList extends StatelessWidget {
  final String groupId;

  ContributionsList({required this.groupId});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('payments')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final contributions = snapshot.data!.docs;
          if (contributions.isEmpty) {
            return Center(
              child: Text('No contributions yet.'),
            );
          }
          return ListView.builder(
            itemCount: contributions.length,
            itemBuilder: (context, index) {
              final contribution = contributions[index];
              final amount = contribution['amount'];
              final timestamp = (contribution['timestamp'] as Timestamp).toDate();
              final status = contribution['status'];

              return ListTile(
                leading: Icon(Icons.monetization_on),
                title: Text('MWK $amount'),
                subtitle: Text(
                  'Date: ${DateFormat('dd MMM yyyy').format(timestamp)}\nStatus: $status',
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error loading contributions.'),
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
