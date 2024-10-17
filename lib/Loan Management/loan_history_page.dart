import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LoanHistoryPage extends StatefulWidget {
  final String userId;
  final String groupId;

  LoanHistoryPage({required this.userId, required this.groupId});

  @override
  _LoanHistoryPageState createState() => _LoanHistoryPageState();
}

class _LoanHistoryPageState extends State<LoanHistoryPage> {
  // Fetch completed loans from Firestore based on userId and groupId
  Stream<QuerySnapshot> _fetchLoanHistory() {
    return FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('loans')
        .where('userId', isEqualTo: widget.userId)
        .where('status', isEqualTo: 'completed') // Fetch completed loans
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loan History'),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchLoanHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No completed loans found.'));
          }

          final loans = snapshot.data!.docs;

          return ListView.builder(
            itemCount: loans.length,
            itemBuilder: (context, index) {
              var loan = loans[index].data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ExpansionTile(
                  title: Text('Loan Amount: MWK ${loan['amount']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Completed On: ${loan['completedAt'].toDate().toString().split(' ')[0]}'),
                      Text('Repayment Period: ${loan['repaymentPeriod']} months'),
                      Text('Total Paid: MWK ${loan['totalWithInterest']}'),
                    ],
                  ),
                  trailing: Icon(Icons.history, color: Colors.blueGrey),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildPaymentHistory(loan['loanId']),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Fetch the payment history for a specific loan from Firestore
  Widget _buildPaymentHistory(String loanId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('loans')
          .doc(loanId)
          .collection('payments')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('No payments found for this loan.');
        }

        final payments = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: payments.map((payment) {
            var paymentData = payment.data() as Map<String, dynamic>;
            return ListTile(
              title: Text('Payment Amount: MWK ${paymentData['amount']}'),
              subtitle: Text('Paid On: ${paymentData['paidAt'].toDate().toString().split(' ')[0]}'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            );
          }).toList(),
        );
      },
    );
  }
}
