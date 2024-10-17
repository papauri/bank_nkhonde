import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PendingLoansPage extends StatefulWidget {
  final String userId;
  final String groupId;

  PendingLoansPage({required this.userId, required this.groupId});

  @override
  _PendingLoansPageState createState() => _PendingLoansPageState();
}

class _PendingLoansPageState extends State<PendingLoansPage> {
  // Fetch pending loans from Firestore based on userId and groupId
  Stream<QuerySnapshot> _fetchPendingLoans() {
    return FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('loans')
        .where('userId', isEqualTo: widget.userId)
        .where('status', isEqualTo: 'pending') // Fetch pending loans
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Loans'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchPendingLoans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No pending loans found.'));
          }

          final loans = snapshot.data!.docs;

          return ListView.builder(
            itemCount: loans.length,
            itemBuilder: (context, index) {
              var loan = loans[index].data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text('Loan Amount: MWK ${loan['amount']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Applied On: ${loan['appliedAt'].toDate().toString().split(' ')[0]}'),
                      Text('Repayment Period: ${loan['repaymentPeriod']} months'),
                      Text('Total with Interest: MWK ${loan['totalWithInterest']}'),
                      Text('Loan Status: Pending Approval'),
                    ],
                  ),
                  trailing: Icon(Icons.hourglass_empty, color: Colors.orangeAccent),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
