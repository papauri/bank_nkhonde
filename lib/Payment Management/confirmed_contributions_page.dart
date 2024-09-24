import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConfirmedContributionsPage extends StatelessWidget {
  final String groupId;

  ConfirmedContributionsPage({required this.groupId});

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
            .collection('confirmedPayments')
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
              final payerName = contribution['payerName'];
              final amount = contribution['amount'];
              final confirmedAt = (contribution['confirmedAt'] as Timestamp).toDate();

              return ListTile(
                title: Text(payerName),
                subtitle: Text('Amount: MWK $amount\nConfirmed at: $confirmedAt'),
              );
            },
          );
        },
      ),
    );
  }
}
