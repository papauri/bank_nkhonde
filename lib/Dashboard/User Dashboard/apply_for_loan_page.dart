import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApplyForLoanPage extends StatefulWidget {
  final String groupId;
  final String userId;
  final double loanAmount; // Confirmed loan amount
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
  String? borrowerName;
  double? loanPenalty; // Fetch the loanPenalty percentage
  DateTime? repaymentDueDate;
  String? transactionReference;

  @override
  void initState() {
    super.initState();
    _fetchBorrowerNameAndLoanPenalty();
    _generateTransactionReference();
  }

  Future<void> _fetchBorrowerNameAndLoanPenalty() async {
    try {
      // Fetch borrower's name
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      // Fetch group data for the loan penalty
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      setState(() {
        borrowerName = userSnapshot['name'] ?? 'Borrower';

        // Cast groupSnapshot data to a Map<String, dynamic> to use containsKey
        final groupData = groupSnapshot.data() as Map<String, dynamic>?;

        // Fetch loanPenalty from the group document
        loanPenalty = (groupData != null && groupData.containsKey('loanPenalty'))
            ? (groupData['loanPenalty'] ?? 0.0).toDouble()
            : 0.0; // Default to 0.0 if not present

        // Set loan due date to the last day of the month, 3 months after loan confirmation
        DateTime now = DateTime.now();
        DateTime threeMonthsLater = DateTime(now.year, now.month + 3, 1);
        repaymentDueDate =
            DateTime(threeMonthsLater.year, threeMonthsLater.month, 0);
      });
    } catch (e) {
      print('Error fetching borrower data: $e');
    }
  }

  Future<void> _generateTransactionReference() async {
    // Generate a transaction reference, like a random number or unique ID
    setState(() {
      transactionReference = DateTime.now().millisecondsSinceEpoch.toString();
    });
  }

  Future<Map<String, dynamic>> _fetchGroupData() async {
    try {
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      QuerySnapshot confirmedPayments = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('status', isEqualTo: 'confirmed')
          .get();

      double availableBalance = confirmedPayments.docs.fold(0.0, (sum, doc) {
        if (['Monthly Contribution', 'Loan Repayment', 'Penalty Fee']
            .contains(doc['paymentType'])) {
          return sum + (doc['amount'] ?? 0.0).toDouble();
        }
        return sum;
      });

      // Fetch loanPenalty from group data
      double loanPenalty = (groupSnapshot['loanPenalty'] ?? 0.0).toDouble();

      return {
        'availableBalance': availableBalance,
        'interestRate': groupSnapshot['interestRate']?.toDouble() ?? 0.0,
        'loanPenalty': loanPenalty, // Keep loanPenalty as the field name
      };
    } catch (e) {
      print('Error fetching group data: $e');
      return {'availableBalance': 0.0, 'interestRate': 0.0, 'loanPenalty': 0.0};
    }
  }

  Future<void> _applyForLoan(BuildContext context) async {
    final String loanAmountStr = _amountController.text.trim();
    double parsedAmount = double.tryParse(loanAmountStr) ?? 0.0;

    if (loanAmountStr.isEmpty || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Please enter a valid loan amount greater than zero')),
      );
      return;
    }

    if (repaymentDueDate == null || borrowerName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please wait while we fetch borrower information.')),
      );
      return;
    }

    try {
      Map<String, dynamic> groupData = await _fetchGroupData();
      double availableBalance = groupData['availableBalance'];
      double interestRate = groupData['interestRate'];

      if (parsedAmount > availableBalance) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Loan amount cannot exceed the available group balance of MWK $availableBalance')),
        );
        return;
      }

      // Corrected logic for outstanding balance: confirmed loan + interest + penalty - repayments
      double totalWithInterestAndPenalty =
          parsedAmount * (1 + interestRate / 100);
      if (groupData['loanPenalty'] != null && groupData['loanPenalty'] > 0) {
        totalWithInterestAndPenalty +=
            parsedAmount * (groupData['loanPenalty'] / 100);
      }

      // Calculate the monthly repayment for the loan
      double monthlyRepayment =
          totalWithInterestAndPenalty / widget.repaymentPeriod;

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
          'borrowerName': borrowerName, // Include borrower's name as borrowerName
          'amount': parsedAmount,
          'interestRate': interestRate, // Interest rate is already a percentage
          'totalWithInterest': totalWithInterestAndPenalty,
          'monthlyRepayment': monthlyRepayment,
          'status': 'pending',
          'appliedAt': Timestamp.now(),
          'dueDate': Timestamp.fromDate(repaymentDueDate!), // Set due date
          'repaymentPeriod': widget.repaymentPeriod,
          'outstandingBalance': totalWithInterestAndPenalty,
          'loanPenalty': groupData['loanPenalty'] ?? 0.0, // Store loanPenalty as percentage in the loan collection
          'transactionReference': transactionReference, // Add the transaction reference here
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
            if (borrowerName != null) ...[
              Text(
                'Borrower: $borrowerName',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
            ],
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
                        style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Interest Rate: ${interestRate.toStringAsFixed(2)}%',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      if (loanPenalty != null && loanPenalty! > 0)
                        Text(
                          'Loan Penalty: ${loanPenalty!.toStringAsFixed(2)}% if late payment',
                          style: TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      if (repaymentDueDate != null)
                        Text(
                          'Repayment Due Date: ${repaymentDueDate!.toLocal().toString().split(' ')[0]}',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      SizedBox(height: 10),
                      Text(
                        'The loan repayment will be divided equally over ${widget.repaymentPeriod} months with the interest rate and loan penalty included.',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Transaction Reference: $transactionReference',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
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
