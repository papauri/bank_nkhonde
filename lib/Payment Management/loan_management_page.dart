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
                      if (loan['status'] == 'approved')
                        IconButton(
                          icon: Icon(Icons.undo, color: Colors.orange),
                          onPressed: () {
                            _revertApproval(loan.id);
                          },
                          tooltip: 'Revert Approval',
                        ),
                      if (loan['status'] == 'pending')
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            _approveLoan(loan.id);
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

  // Approve Loan
  void _approveLoan(String loanId) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('loans')
          .doc(loanId)
          .update({
        'status': 'approved',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loan approved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve loan. Try again.')),
      );
    }
  }

  // Revert loan approval back to pending
  void _revertApproval(String loanId) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('loans')
          .doc(loanId)
          .update({
        'status': 'pending',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loan approval reverted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to revert approval. Try again.')),
      );
    }
  }

  // Reject Loan
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject loan. Try again.')),
      );
    }
  }
}
