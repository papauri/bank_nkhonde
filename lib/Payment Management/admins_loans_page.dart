import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoansPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  LoansPage({required this.groupId, required this.groupName});

  @override
  _LoansPageState createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  double interestRate = 0.0;
  double availableBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
    _fetchAvailableBalance();
  }

  Future<void> _fetchGroupData() async {
    try {
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupSnapshot.exists) {
        setState(() {
          interestRate = (groupSnapshot['interestRate'] ?? 0.0).toDouble() / 100;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch group data.')),
      );
    }
  }

  Future<void> _fetchAvailableBalance() async {
    try {
      double monthlyContributions = 0.0;
      double loanRepayments = 0.0;
      double interestPayments = 0.0;
      double penaltyFees = 0.0;

      QuerySnapshot paymentsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('status', isEqualTo: 'confirmed')
          .get();

      for (var payment in paymentsSnapshot.docs) {
        String paymentType = payment['paymentType'];
        double amount = (payment['amount'] ?? 0.0).toDouble();

        if (paymentType == 'Monthly Contribution') {
          monthlyContributions += amount;
        } else if (paymentType == 'Loan Repayment') {
          loanRepayments += amount;
        } else if (paymentType == 'Interest') {
          interestPayments += amount;
        } else if (paymentType == 'Penalty') {
          penaltyFees += amount;
        }
      }

      setState(() {
        availableBalance = monthlyContributions + loanRepayments + interestPayments + penaltyFees;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to calculate available balance.')),
      );
    }
  }

  Future<String> _fetchUserName(String userId) async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        return userSnapshot['name'] ?? 'Unknown Member';
      } else {
        return 'Unknown Member';
      }
    } catch (e) {
      return 'Unknown Member';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loans Overview - ${widget.groupName}'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Available Balance: MWK ${availableBalance.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
          ),
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('loans')
                  .get(),
              builder: (context, loanSnapshot) {
                if (!loanSnapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final loans = loanSnapshot.data!.docs;

                return ListView.builder(
                  itemCount: loans.length,
                  itemBuilder: (context, index) {
                    final loan = loans[index];
                    final loanId = loan.id;
                    final userId = loan['userId'];
                    final loanAmount = loan['amount']?.toDouble() ?? 0.0;
                    final loanStatus = loan['status'] ?? 'pending';
                    final totalWithInterest = loanAmount * (1 + interestRate);

                    return FutureBuilder<String>(
                      future: _fetchUserName(userId),
                      builder: (context, userNameSnapshot) {
                        if (!userNameSnapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final payerName = userNameSnapshot.data!;

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          elevation: 4,
                          child: ListTile(
                            title: Text(
                              'Member: $payerName',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(
                              'Loan Amount: MWK ${loanAmount.toStringAsFixed(2)}\n'
                              'Interest Rate: ${(interestRate * 100).toStringAsFixed(2)}%\n'
                              'Total Amount to Repay: MWK ${totalWithInterest.toStringAsFixed(2)}\n'
                              'Status: $loanStatus',
                              style: TextStyle(fontSize: 16),
                            ),
                            trailing: loanStatus == 'pending'
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => _showApproveLoanDialog(loanId, loanAmount, totalWithInterest),
                                        child: Text('Approve'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () => _showDenyLoanDialog(loanId),
                                        child: Text('Deny'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                      ),
                                    ],
                                  )
                                : loanStatus == 'approved'
                                    ? Icon(Icons.check_circle, color: Colors.green)
                                    : Icon(Icons.cancel, color: Colors.red),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveLoanDialog(String loanId, double loanAmount, double totalWithInterest) {
    TextEditingController amountController = TextEditingController(text: loanAmount.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Approve Loan Application'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Available Balance: MWK ${availableBalance.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Approved Loan Amount',
                  helperText: 'Edit the amount if needed',
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Total with Interest: MWK ${(double.parse(amountController.text) * (1 + interestRate)).toStringAsFixed(2)}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                double approvedAmount = double.parse(amountController.text);
                double approvedTotal = approvedAmount * (1 + interestRate);
                _approveLoanConfirmed(loanId, approvedAmount, approvedTotal);
                Navigator.of(context).pop();
              },
              child: Text('Approve Loan'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        );
      },
    );
  }

  Future<void> _approveLoanConfirmed(String loanId, double approvedAmount, double totalWithInterest) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('loans')
          .doc(loanId)
          .update({
        'status': 'approved',
        'approvedAmount': approvedAmount,
        'totalWithInterest': totalWithInterest,
      });

      // Deduct the loan amount from available balance
      setState(() {
        availableBalance -= approvedAmount;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loan approved successfully!')),
      );

      setState(() {}); // Refresh the page after approval
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve loan. Please try again.')),
      );
    }
  }

  void _showDenyLoanDialog(String loanId) {
    TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Deny Loan Application'),
          content: TextField(
            controller: reasonController,
            decoration: InputDecoration(
              labelText: 'Reason for denial',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _denyLoanConfirmed(loanId, reasonController.text);
                Navigator.of(context).pop();
              },
              child: Text('Deny Loan'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  Future<void> _denyLoanConfirmed(String loanId, String reason) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('loans')
          .doc(loanId)
          .update({
        'status': 'denied',
        'denialReason': reason,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loan denied successfully.')),
      );

      setState(() {}); // Refresh the page after denial
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to deny loan. Please try again.')),
      );
    }
  }
}
