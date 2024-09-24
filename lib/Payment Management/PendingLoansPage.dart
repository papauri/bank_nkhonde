import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PendingLoansPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  PendingLoansPage({required this.groupId, required this.groupName});

  @override
  _PendingLoansPageState createState() => _PendingLoansPageState();
}

class _PendingLoansPageState extends State<PendingLoansPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Loans - ${widget.groupName}'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('members')
            .get(),
        builder: (context, memberSnapshot) {
          if (!memberSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final members = memberSnapshot.data!.docs;

          if (members.isEmpty) {
            return Center(child: Text('No members in this group.'));
          }

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('groups')
                .doc(widget.groupId)
                .collection('loans')
                .where('status', isEqualTo: 'pending')
                .get(),
            builder: (context, loanSnapshot) {
              if (!loanSnapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final loans = loanSnapshot.data!.docs;

              // Create a map of userId to loan data for quick lookup
              Map<String, dynamic> loanMap = {
                for (var loan in loans) loan['userId']: loan
              };

              return ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final memberId = member.id;
                  final memberName = member['name'] ?? 'Unknown Member';

                  // Check if a loan exists for this member
                  final memberLoan = loanMap[memberId];

                  // If no loan is found, show default text
                  final loanAmount = memberLoan != null
                      ? memberLoan['amount']?.toDouble() ?? 0.0
                      : 0.0;
                  final loanStatus = memberLoan != null
                      ? 'Applied'
                      : 'Not Applied';
                  final loanId = memberLoan != null ? memberLoan.id : '';

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    elevation: 4,
                    child: ListTile(
                      title: Text(
                        memberName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        'Loan Amount: MWK ${loanAmount.toStringAsFixed(2)}\nStatus: $loanStatus',
                        style: TextStyle(fontSize: 16),
                      ),
                      trailing: loanStatus == 'Applied'
                          ? ElevatedButton(
                              onPressed: () {
                                _approveLoan(loanId);
                              },
                              child: Text('Approve Loan'),
                            )
                          : null,
                    ),
                  );
                },
              );
            },
          );
        },
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
          .update({'status': 'approved'});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loan approved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve loan. Please try again.')),
      );
    }
  }
}
