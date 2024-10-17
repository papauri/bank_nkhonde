import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ActiveLoansPage extends StatefulWidget {
  final String userId;
  final String groupId;

  ActiveLoansPage({required this.userId, required this.groupId});

  @override
  _ActiveLoansPageState createState() => _ActiveLoansPageState();
}

class _ActiveLoansPageState extends State<ActiveLoansPage> {
  // Fetch active loans from Firestore based on userId and groupId
  Stream<QuerySnapshot> _fetchActiveLoans() {
    return FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('loans')
        .where('userId', isEqualTo: widget.userId)
        .where('status', isEqualTo: 'approved') // Fetch approved (active) loans
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Active Loans'),
        backgroundColor: Colors.blueGrey,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchActiveLoans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No active loans found.'));
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
                      Text('Start Date: ${loan['appliedAt'].toDate().toString().split(' ')[0]}'),
                      Text('Next Payment Due: ${loan['dueDate'].toDate().toString().split(' ')[0]}'),
                      Text('Monthly Repayment: MWK ${loan['monthlyRepayment']}'),
                      Text('Outstanding Balance: MWK ${loan['outstandingBalance']}'),
                    ],
                  ),
                  trailing: Icon(Icons.account_balance_wallet, color: Colors.blueAccent),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
