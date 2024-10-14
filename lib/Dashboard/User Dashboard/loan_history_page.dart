import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'users_loan_details_page.dart';

class LoanHistoryPage extends StatefulWidget {
  final String groupId;
  final String userId;

  LoanHistoryPage({required this.groupId, required this.userId});

  @override
  _LoanHistoryPageState createState() => _LoanHistoryPageState();
}

class _LoanHistoryPageState extends State<LoanHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loan History', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('loans')
            .where('userId', isEqualTo: widget.userId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No loan history available.'));
          }

          final loans = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: loans.length,
            itemBuilder: (context, index) {
              final loanData = loans[index].data() as Map<String, dynamic>;
              final double loanAmount = (loanData['amount'] ?? 0.0).toDouble();
              final double interestRate = (loanData['interestRate'] ?? 0.0).toDouble();
              final String status = loanData['status'] ?? 'Completed';
              final DateTime applicationDate = (loanData['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
              final double penaltyFee = (loanData['penaltyFee'] ?? 0.0).toDouble();

              return ExpansionTile(
                title: Text('Loan Amount: MWK ${loanAmount.toStringAsFixed(2)}'),
                subtitle: Text('Applied on: ${DateFormat('dd MMM yyyy').format(applicationDate)}'),
                children: [
                  _buildDetailRow('Interest Rate', '${interestRate.toStringAsFixed(2)}%'),
                  _buildDetailRow('Status', status),
                  _buildDetailRow('Penalty Fee', 'MWK ${penaltyFee.toStringAsFixed(2)}'),
                  SizedBox(height: 10),
                  _buildPaymentDetails(loanData),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Loan History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Repayments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              // Stay on the current page (Loan History)
              break;
            case 1:
              // Navigate to Loan Repayments (or UsersLoanDetailsPage)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UsersLoanDetailsPage(
                    groupId: widget.groupId,
                    userId: widget.userId,
                  ),
                ),
              );
              break;
            case 2:
              // Navigate back to the dashboard or admin dashboard
              Navigator.pop(context); // Assuming dashboard is a previous screen
              break;
          }
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.black)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? Colors.black)),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(Map<String, dynamic> loanData) {
    final payments = loanData['payments'] as List<dynamic>? ?? [];
    
    if (payments.isEmpty) {
      return Text('No payments made yet.', style: TextStyle(color: Colors.grey));
    }

    return Column(
      children: payments.map((payment) {
        final DateTime paymentDate = (payment['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now();
        final double paymentAmount = (payment['amount'] ?? 0.0).toDouble();
        final bool isPenaltyApplied = (payment['penaltyApplied'] ?? false);
        final String paymentStatus = payment['status'] ?? 'Pending';

        return ListTile(
          title: Text('Paid MWK ${paymentAmount.toStringAsFixed(2)}'),
          subtitle: Text('Date: ${DateFormat('dd MMM yyyy').format(paymentDate)}'),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(paymentStatus, style: TextStyle(color: paymentStatus == 'Completed' ? Colors.green : Colors.redAccent)),
              if (isPenaltyApplied) Text('Penalty Applied', style: TextStyle(color: Colors.red)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
