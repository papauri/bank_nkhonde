import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'loan_repayment_page.dart';
import 'loan_history_page.dart'; // Create this page

class UsersLoanDetailsPage extends StatefulWidget {
  final String groupId;
  final String userId;

  UsersLoanDetailsPage({required this.groupId, required this.userId});

  @override
  _UsersLoanDetailsPageState createState() => _UsersLoanDetailsPageState();
}

class _UsersLoanDetailsPageState extends State<UsersLoanDetailsPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoanHistoryPage(
              groupId: widget.groupId,
              userId: widget.userId,
            ),
          ),
        );
        break;
      case 1:
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
        Navigator.pop(context); // Assuming dashboard is the previous screen
        break;
    }
  }

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
              final DateTime applicationDate = (loanData['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

              // Calculate due dates
              DateTime nextPaymentDate = (loanData['nextPaymentDueDate'] as Timestamp?)?.toDate() ?? DateTime(applicationDate.year, applicationDate.month + 1, 0);
              DateTime finalDueDate = (loanData['finalDueDate'] as Timestamp?)?.toDate() ?? DateTime(applicationDate.year, applicationDate.month + repaymentPeriod, 0);

              final String totalPayable = (loanAmount * (1 + interestRate / 100)).toStringAsFixed(2);
              final String monthlyRepayment = (loanAmount * (1 + interestRate / 100) / repaymentPeriod).toStringAsFixed(2);

              return GestureDetector(
                onTap: () {
                  if (outstandingBalance > 0) {
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
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoanHistoryPage(
                          groupId: widget.groupId,
                          userId: widget.userId,
                        ),
                      ),
                    );
                  }
                },
                child: Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Outstanding Balance', 'MWK ${outstandingBalance.toStringAsFixed(2)}', outstandingBalance > 0 ? Colors.redAccent : Colors.green),
                        _buildDetailRow('Next Payment Due', DateFormat('dd MMM yyyy').format(nextPaymentDate), Colors.blueAccent),
                        _buildDetailRow('Loan Amount', 'MWK ${loanAmount.toStringAsFixed(2)}'),
                        _buildDetailRow('Interest Rate', '${interestRate.toStringAsFixed(2)}%'),
                        _buildDetailRow('Total Payable', 'MWK $totalPayable'),
                        _buildDetailRow('Monthly Repayment', 'MWK $monthlyRepayment'),
                        _buildDetailRow('Final Due Date', DateFormat('dd MMM yyyy').format(finalDueDate), Colors.redAccent),
                        _buildDetailRow('Status', status, status == 'approved' ? Colors.green : Colors.redAccent),
                        SizedBox(height: 10),
                        Text(
                          outstandingBalance > 0 ? 'Tap for Loan Payments' : 'Tap for Loan History',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
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
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
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
}
