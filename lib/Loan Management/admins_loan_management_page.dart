import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LoanManagementPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  LoanManagementPage({required this.groupId, required this.groupName});

  @override
  _LoanManagementPageState createState() => _LoanManagementPageState();
}

class _LoanManagementPageState extends State<LoanManagementPage> {
  Future<void> _refreshLoans() async {
    setState(() {}); // Trigger a UI refresh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loan Management'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshLoans,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .collection('loans')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final loans = snapshot.data!.docs;

            if (loans.isEmpty) {
              return Center(child: Text('No loan requests available.'));
            }

            return ListView.builder(
              itemCount: loans.length,
              itemBuilder: (context, index) {
                final loan = loans[index];
                DateTime dueDate = (loan['dueDate'] as Timestamp).toDate();
                DateTime appliedAt = (loan['appliedAt'] as Timestamp).toDate();
                String formattedDueDate = DateFormat('dd MMM yyyy').format(dueDate);
                String formattedAppliedAt = DateFormat('dd MMM yyyy').format(appliedAt);
                String transactionReference = loan['transactionReference'] ?? 'N/A';
                double loanPenalty = loan['loanPenalty'] ?? 0.0;
                double loanAmount = loan['amount'];

                return ListTile(
                  title: Text('Loan from ${loan['borrowerName']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amount: MWK ${loanAmount.toStringAsFixed(2)}'),
                      Text('Transaction Ref: $transactionReference'),
                      Text('Applied On: $formattedAppliedAt'),
                      Text('Status: ${loan['status']}'),
                      Text('Repayment Due: $formattedDueDate'),
                      if (loanPenalty > 0)
                        Text('Penalty: ${loanPenalty.toStringAsFixed(2)}%'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (loan['status'] == 'pending')
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            _approveLoan(loan.id, loanAmount);
                          },
                          tooltip: 'Approve Loan',
                        ),
                      IconButton(
                        icon: Icon(Icons.clear, color: Colors.red),
                        onPressed: () {
                          _rejectLoan(loan.id);
                        },
                        tooltip: 'Reject Loan',
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Function to calculate available balance dynamically
  Future<double> _calculateAvailableBalance() async {
    try {
      QuerySnapshot contributionsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('paymentType', isEqualTo: 'Monthly Contribution')
          .where('status', isEqualTo: 'confirmed')
          .get();

      QuerySnapshot loanRepaymentsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('paymentType', isEqualTo: 'Loan Repayment')
          .where('status', isEqualTo: 'confirmed')
          .get();

      QuerySnapshot seedMoneySnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('paymentType', isEqualTo: 'Seed Money')
          .where('status', isEqualTo: 'confirmed')
          .get();

      QuerySnapshot penaltiesSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('paymentType', isEqualTo: 'Penalty Fee')
          .where('status', isEqualTo: 'confirmed')
          .get();

      QuerySnapshot loansSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('loans')
          .where('status', isEqualTo: 'approved')
          .get();

      // Calculate total contributions
      double totalContributions = contributionsSnapshot.docs.fold(0.0, (sum, doc) {
        return sum + (doc['amount'] ?? 0.0).toDouble();
      });

      // Calculate total loan repayments
      double totalLoanRepayments = loanRepaymentsSnapshot.docs.fold(0.0, (sum, doc) {
        return sum + (doc['amount'] ?? 0.0).toDouble();
      });

      // Calculate total seed money
      double totalSeedMoney = seedMoneySnapshot.docs.fold(0.0, (sum, doc) {
        return sum + (doc['amount'] ?? 0.0).toDouble();
      });

      // Calculate total penalties
      double totalPenalties = penaltiesSnapshot.docs.fold(0.0, (sum, doc) {
        return sum + (doc['amount'] ?? 0.0).toDouble();
      });

      // Calculate total approved loans
      double totalLoans = loansSnapshot.docs.fold(0.0, (sum, doc) {
        return sum + (doc['amount'] ?? 0.0).toDouble();
      });

      // Available balance = Total Contributions + Seed Money + Loan Repayments - Approved Loans - Penalties
      double availableBalance = totalContributions + totalSeedMoney + totalLoanRepayments - totalLoans - totalPenalties;

      return availableBalance;
    } catch (e) {
      print('Error calculating available balance: $e');
      return 0.0;
    }
  }

  // Function to approve the loan
  void _approveLoan(String loanId, double loanAmount) async {
    try {
      // Fetch the available balance dynamically
      double availableBalance = await _calculateAvailableBalance();

      if (loanAmount > availableBalance) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Insufficient funds to approve the loan.')),
        );
        return;
      }

      DocumentSnapshot loanSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('loans')
          .doc(loanId)
          .get();

      if (!loanSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loan not found.')),
        );
        return;
      }

      String transactionReference = loanSnapshot['transactionReference'] ?? '';
      if (transactionReference.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loan missing transaction reference.')),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('loans')
          .doc(loanId)
          .update({
        'status': 'approved',
        'approvedAt': Timestamp.now(),
        'transactionReference': transactionReference,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loan approved successfully!')),
      );
    } catch (e) {
      print('Error approving loan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve loan. Try again.')),
      );
    }
  }

  // Function to reject the loan
  void _rejectLoan(String loanId) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('loans')
          .doc(loanId)
          .update({
        'status': 'rejected',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loan rejected.')),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject loan. Try again.')),
      );
    }
  }
}
