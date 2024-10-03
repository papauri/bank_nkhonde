import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PenaltyPaymentPage extends StatelessWidget {
  final String groupId;

  PenaltyPaymentPage({required this.groupId});

  Future<double> _fetchPenaltyFee() async {
    // Fetch penalty fee from Firestore
    try {
      DocumentSnapshot penaltyDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .get();
      return penaltyDoc['penaltyFee']?.toDouble() ?? 0.0;
    } catch (e) {
      print('Error fetching penalty fee: $e');
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: _fetchPenaltyFee(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        double penaltyFee = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Late Payment Penalty: MWK $penaltyFee'),
          ],
        );
      },
    );
  }
}
