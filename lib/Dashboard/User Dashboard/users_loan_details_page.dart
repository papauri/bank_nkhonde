import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UsersLoanDetailsPage extends StatelessWidget {
  final String groupId;
  final String userId;

  UsersLoanDetailsPage({required this.groupId, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Loan Details',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('loans')
            .where('userId', isEqualTo: userId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No loan details available.'));
          }

          final loans = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: loans.length,
            itemBuilder: (context, index) {
              final loanData = loans[index].data() as Map<String, dynamic>;
              final amount = (loanData['amount'] ?? 0.0).toDouble();
              final interestRate = (loanData['interestRate'] ?? 0.0).toDouble();
              final status = loanData['status'] ?? 'Pending';
              final int repaymentPeriod = loanData['repaymentPeriod'] ?? 4; // Repayment period in months (default to 4)
              final DateTime applicationDate = (loanData['appliedAt'] as Timestamp).toDate();
              final DateTime calculatedDueDate = applicationDate.add(Duration(days: 30 * repaymentPeriod));
              
              final totalPayable = (amount * (1 + interestRate / 100)).toStringAsFixed(2);
              final monthlyRepayment = (amount * (1 + interestRate / 100) / repaymentPeriod).toStringAsFixed(2);

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loan Amount: MWK ${amount.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Interest Rate: ${interestRate.toStringAsFixed(2)}%',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Total Payable: MWK $totalPayable',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Monthly Repayment ($repaymentPeriod months): MWK $monthlyRepayment',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Due Date: ${DateFormat('dd MMM yyyy').format(calculatedDueDate)}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Status: $status',
                        style: TextStyle(
                          fontSize: 16,
                          color: status == 'approved' ? Colors.green : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
