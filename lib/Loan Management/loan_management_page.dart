import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                return ListTile(
                  title: Text('Loan Request from ${loan['borrowerName']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amount: \$${loan['amount']}'),
                      Text('Status: ${loan['status']}'),
                      Text('Repayment Due: ${loan['repaymentDueDate']}'),
                    ],
                  ),
                  trailing: loan['status'] == 'pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                        )
                      : null,
                );
              },
            );
          },
        ),
      ),
    );
  }

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
