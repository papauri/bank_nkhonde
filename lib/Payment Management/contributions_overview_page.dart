import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ContributionsOverviewPage extends StatelessWidget {
  final String groupId;

  ContributionsOverviewPage({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmed Contributions'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('payments')
            .where('status', isEqualTo: 'confirmed') // Filter for confirmed payments
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final contributions = snapshot.data!.docs;

          if (contributions.isEmpty) {
            return Center(child: Text('No confirmed contributions yet.'));
          }

          return ListView.builder(
            itemCount: contributions.length,
            itemBuilder: (context, index) {
              final contribution = contributions[index];
              final paymentDate = contribution['paymentDate'].toDate();
              final formattedDate = DateFormat('EEEE, MMM d, y').format(paymentDate);

              return ListTile(
                title: Text('Payer: ${contribution['payerName']}'),
                subtitle: Text('Amount: MWK ${contribution['amount']}'),
                trailing: Text('Confirmed on: $formattedDate'), // Display user-friendly date
              );
            },
          );
        },
      ),
    );
  }
}
