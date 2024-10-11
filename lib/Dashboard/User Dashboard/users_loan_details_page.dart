import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'loan_repayment_page.dart'; // Assuming you have this page

class UsersLoanDetailsPage extends StatefulWidget {
  final String groupId;
  final String userId;

  UsersLoanDetailsPage({required this.groupId, required this.userId});

  @override
  _UsersLoanDetailsPageState createState() => _UsersLoanDetailsPageState();
}

class _UsersLoanDetailsPageState extends State<UsersLoanDetailsPage> {
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
            .doc(widget.groupId)
            .collection('loans')
            .where('userId', isEqualTo: widget.userId)
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
              final double loanAmount = (loanData['amount'] ?? 0.0).toDouble();
              final double interestRate = (loanData['interestRate'] ?? 0.0).toDouble();
              final String status = loanData['status'] ?? 'Pending';
              final int repaymentPeriod = loanData['repaymentPeriod'] ?? 3;
              final double outstandingBalance = (loanData['outstandingBalance'] ?? loanAmount).toDouble();
              final DateTime applicationDate = (loanData['appliedAt'] != null)
                  ? (loanData['appliedAt'] as Timestamp).toDate()
                  : DateTime.now();
              
              // Calculate Next Payment Date or fallback to last day of current month
              DateTime nextPaymentDate = (loanData['nextPaymentDueDate'] != null)
                  ? (loanData['nextPaymentDueDate'] as Timestamp).toDate()
                  : DateTime(applicationDate.year, applicationDate.month + 1, 0);  // Last day of next month
              
              // Calculate Final Due Date: Based on either admin-specified date or the repayment period
              DateTime finalDueDate = (loanData['finalDueDate'] != null)
                  ? (loanData['finalDueDate'] as Timestamp).toDate()
                  : DateTime(applicationDate.year, applicationDate.month + repaymentPeriod, 0); // Last day of final month

              final String totalPayable = (loanAmount * (1 + interestRate / 100)).toStringAsFixed(2);
              final String monthlyRepayment = (loanAmount * (1 + interestRate / 100) / repaymentPeriod).toStringAsFixed(2);

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Outstanding Balance
                      Text(
                        'Outstanding Balance: MWK ${outstandingBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: outstandingBalance > 0 ? Colors.redAccent : Colors.green,
                        ),
                      ),
                      SizedBox(height: 10),

                      // Next Payment Date
                      Text(
                        'Next Payment Due: ${DateFormat('dd MMM yyyy').format(nextPaymentDate)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      SizedBox(height: 10),

                      // Loan Amount
                      Text(
                        'Loan Amount: MWK ${loanAmount.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),

                      // Interest Rate
                      Text(
                        'Interest Rate: ${interestRate.toStringAsFixed(2)}%',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),

                      // Total Payable
                      Text(
                        'Total Payable: MWK $totalPayable',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),

                      // Monthly Repayment
                      Text(
                        'Monthly Repayment ($repaymentPeriod months): MWK $monthlyRepayment',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),

                      // Final Due Date
                      Text(
                        'Final Due Date: ${DateFormat('dd MMM yyyy').format(finalDueDate)}',
                        style: TextStyle(fontSize: 16, color: Colors.redAccent),
                      ),
                      SizedBox(height: 10),

                      // Loan Status
                      Text(
                        'Status: $status',
                        style: TextStyle(
                          fontSize: 16,
                          color: status == 'approved' ? Colors.green : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),

                      // Make a Payment Button
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to LoanRepaymentPage with relevant loan data
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoanRepaymentPage(
                                groupId: widget.groupId,
                                userId: widget.userId,
                                loanAmount: loanAmount,
                                interestRate: interestRate,
                                repaymentPeriod: repaymentPeriod,
                                outstandingBalance: outstandingBalance,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal, // Button color
                        ),
                        child: Text('Make a Loan Repayment'),
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
