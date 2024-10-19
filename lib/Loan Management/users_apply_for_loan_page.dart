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

      // Fetch interestRate and loanPenalty from the group document
      double loanPenalty = (groupSnapshot['loanPenalty'] ?? 0.0).toDouble();
      double interestRate = (groupSnapshot['interestRate'] ?? 0.0).toDouble();

      return {
        'availableBalance': availableBalance,
        'interestRate': interestRate,
        'loanPenalty': loanPenalty,
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
      SnackBar(content: Text('Please enter a valid loan amount greater than zero')),
    );
    return;
  }

  if (repaymentDueDate == null || borrowerName == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please wait while we fetch borrower information.')),
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

    // Generate unique loan ID
    String loanId = _generateLoanId();

    // Total amount with interest
    double totalWithInterestAndPenalty = parsedAmount * (1 + interestRate / 100);
    if (groupData['loanPenalty'] != null && groupData['loanPenalty'] > 0) {
      totalWithInterestAndPenalty += parsedAmount * (groupData['loanPenalty'] / 100);
    }

    double monthlyRepayment = totalWithInterestAndPenalty / widget.repaymentPeriod;

    // Add loan to the Firestore
    var loanDocument = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('loans')
        .doc(loanId);

    await loanDocument.set({
      'loanId': loanId, // Store the unique Loan ID
      'userId': widget.userId,
      'borrowerName': borrowerName,
      'amount': parsedAmount,
      'interestRate': interestRate,
      'totalWithInterest': totalWithInterestAndPenalty,
      'monthlyRepayment': monthlyRepayment,
      'status': 'pending',
      'appliedAt': Timestamp.now(),
      'dueDate': Timestamp.fromDate(repaymentDueDate!),
      'repaymentPeriod': widget.repaymentPeriod,
      'outstandingBalance': totalWithInterestAndPenalty,
      'loanPenalty': groupData['loanPenalty'] ?? 0.0,
      'transactionReference': transactionReference,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loan application submitted successfully! Loan ID: $loanId')),
    );

    Navigator.pop(context); // Close the page after loan submission
  } catch (e) {
    print('Error applying for loan: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to apply for loan. Please try again.')),
    );
  }
}

// Generate a unique Loan ID for each loan
String _generateLoanId() {
  return DateTime.now().millisecondsSinceEpoch.toString(); // Or use any other method for unique ID
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
