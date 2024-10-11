import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApplyForLoanPage extends StatefulWidget {
  final String groupId;
  final String userId;
  final double loanAmount;  // Confirmed loan amount
  final double interestRate; // Interest rate of the loan
  final int repaymentPeriod; // Loan repayment period in months
  final double outstandingBalance; // Outstanding loan balance to be updated

  ApplyForLoanPage({
    required this.groupId,
    required this.userId,
    required this.loanAmount,
    required this.interestRate,
    required this.repaymentPeriod,
    required this.outstandingBalance,
  });

  @override
  _ApplyForLoanPageState createState() => _ApplyForLoanPageState();
}

class _ApplyForLoanPageState extends State<ApplyForLoanPage> {
  final TextEditingController _amountController = TextEditingController();

  Future<Map<String, dynamic>> _fetchGroupData() async {
    try {
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();
      double interestRate = (groupSnapshot['interestRate'] ?? 0.0).toDouble() / 100;

      QuerySnapshot confirmedPayments = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('status', isEqualTo: 'confirmed')
          .get();

      double availableBalance = 0.0;

      for (var doc in confirmedPayments.docs) {
        String paymentType = doc['paymentType'];
        if (paymentType == 'Monthly Contribution' || paymentType == 'Loan Repayment' || paymentType == 'Penalty Fee') {
          availableBalance += (doc['amount'] ?? 0.0).toDouble();
        }
      }

      return {
        'availableBalance': availableBalance,
        'interestRate': interestRate,
      };
    } catch (e) {
      print('Error fetching group data: $e');
      return {
        'availableBalance': 0.0,
        'interestRate': 0.0,
      };
    }
  }

  Future<void> _applyForLoan(BuildContext context) async {
    final String loanAmountStr = _amountController.text.trim();
    double parsedAmount = double.tryParse(loanAmountStr) ?? 0.0;

    if (loanAmountStr.isEmpty || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid loan amount greater than zero')),
      );
      return;
    }

    try {
      Map<String, dynamic> groupData = await _fetchGroupData();
      double availableBalance = groupData['availableBalance'];
      double interestRate = groupData['interestRate'];

      if (parsedAmount > availableBalance) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loan amount cannot exceed the available group balance of MWK $availableBalance')),
        );
        return;
      }

      double totalWithInterest = parsedAmount * (1 + interestRate);
      double monthlyRepayment = totalWithInterest / 3;  // Example: repay over 3 months
      DateTime now = DateTime.now();
      DateTime dueDate = DateTime(now.year, now.month + 3, 0);  // 3 months from now

      var loanQuerySnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('loans')
          .where('userId', isEqualTo: widget.userId)
          .get();

      if (loanQuerySnapshot.docs.isEmpty) {
        var loanDocument = FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('loans')
            .doc();

        await loanDocument.set({
          'userId': widget.userId,
          'amount': parsedAmount,
          'interestRate': interestRate * 100,
          'totalWithInterest': totalWithInterest,
          'monthlyRepayment': monthlyRepayment,
          'status': 'pending',
          'appliedAt': Timestamp.now(),
          'dueDate': Timestamp.fromDate(dueDate),
          'repaymentPeriod': widget.repaymentPeriod,
          'outstandingBalance': totalWithInterest,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loan application submitted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You already have an active loan application.')),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      print('Error applying for loan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to apply for loan. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Apply for Loan', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: _fetchGroupData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return Text('Error: Could not retrieve group data');
                } else {
                  final groupData = snapshot.data!;
                  final availableBalance = groupData['availableBalance'];
                  final interestRate = groupData['interestRate'];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Available Balance to Borrow: MWK ${availableBalance.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Interest Rate: ${(interestRate * 100).toStringAsFixed(2)}%',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'The loan repayment will be divided equally for the next 3 months with the interest rate included.',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  );
                }
              },
            ),
            SizedBox(height: 20),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Loan Amount',
                border: OutlineInputBorder(),
                hintText: 'Enter the amount you want to borrow',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _applyForLoan(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Submit Loan Application',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
