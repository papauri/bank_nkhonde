import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // For image uploading
import 'dart:io'; // To handle file types

class LoanRepaymentPage extends StatefulWidget {
  final String groupId;
  final String userId;

  LoanRepaymentPage({
    required this.groupId,
    required this.userId, required double interestRate, required double loanAmount, required int repaymentPeriod, required double outstandingBalance,
  });

  @override
  _LoanRepaymentPageState createState() => _LoanRepaymentPageState();
}

class _LoanRepaymentPageState extends State<LoanRepaymentPage> {
  double monthlyPayment = 0.0;
  double outstandingLoanBalance = 0.0;
  String? transactionReference;
  TextEditingController _paymentController = TextEditingController();
  File? _paymentScreenshot;
  List<DocumentSnapshot> userLoans = []; // List of loans
  DocumentSnapshot? selectedLoan; // The selected loan document
  String? selectedLoanId; // ID of the selected loan
  double loanAmount = 0.0;
  double interestRate = 0.0;
  int repaymentPeriod = 0;
  double outstandingBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchUserLoans();
  }

  // Fetch all loans of the user
  Future<void> _fetchUserLoans() async {
    try {
      QuerySnapshot loanQuerySnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('loans')
          .where('userId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'approved') // Only approved loans
          .get();

      if (loanQuerySnapshot.docs.isNotEmpty) {
        setState(() {
          userLoans = loanQuerySnapshot.docs;
          selectedLoan = userLoans.first; // Default to the first loan
          selectedLoanId = selectedLoan?.id;
          _updateLoanDetails(selectedLoan);
        });
      }
    } catch (e) {
      print('Error fetching user loans: $e');
    }
  }

  // Update the loan details when a loan is selected
  void _updateLoanDetails(DocumentSnapshot? loan) {
    if (loan != null) {
      loanAmount = loan['amount'];
      interestRate = loan['interestRate'];
      repaymentPeriod = loan['repaymentPeriod'];
      outstandingBalance = loan['outstandingBalance'];

      double totalLoan = loanAmount * (1 + interestRate / 100);
      monthlyPayment = totalLoan / repaymentPeriod;
      outstandingLoanBalance = outstandingBalance;
      transactionReference = loan['transactionReference'];

      setState(() {
        _paymentController.text = monthlyPayment.toStringAsFixed(2);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _paymentScreenshot = File(pickedFile.path);
      });
    }
  }

Future<void> _makePayment() async {
  double paymentAmount = double.tryParse(_paymentController.text) ?? 0.0;

  if (paymentAmount > 0 && selectedLoanId != null) {
    try {
      // Check if transactionReference exists, if not, create a new one
      if (transactionReference == null || transactionReference!.isEmpty) {
        transactionReference = _generateTransactionReference();
      }

      // Add payment record with status 'pending' for admin approval
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .add({
        'userId': widget.userId,
        'loanId': selectedLoanId, // Reference the selected loan
        'paymentType': 'Loan Repayment',
        'amount': paymentAmount,
        'status': 'pending', // Payment pending approval
        'paymentDate': Timestamp.now(),
        'referenceNumber': transactionReference, // Add transaction reference
        'screenshot': _paymentScreenshot != null ? await _uploadScreenshot() : null,
      });

      // Show a dialog to inform the user about the payment status
      _showPaymentPendingDialog();
    } catch (e) {
      print('Error making payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Payment failed. Please try again.'),
      ));
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Please fill in a valid payment amount and select a loan.'),
    ));
  }
}
// Method to generate a new transaction reference (e.g., a random string or ID)
String _generateTransactionReference() {
  return DateTime.now().millisecondsSinceEpoch.toString(); // Example reference
}

// Method to show the payment pending dialog
void _showPaymentPendingDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Payment Pending'),
        content: Text('Your payment has been submitted and is pending admin approval.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.of(context).pop(); // Close the repayment page
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}
  Future<String> _uploadScreenshot() async {
    // Placeholder logic to upload screenshot, return dummy URL
    return 'https://example.com/screenshot.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loan Repayment', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userLoans.isNotEmpty)
              DropdownButton<String>(
                value: selectedLoanId,
                hint: Text('Select Loan'),
                onChanged: (newValue) {
                  setState(() {
                    selectedLoanId = newValue;
                    selectedLoan = userLoans.firstWhere((loan) => loan.id == newValue);
                    _updateLoanDetails(selectedLoan);
                  });
                },
                items: userLoans.map<DropdownMenuItem<String>>((loan) {
                  return DropdownMenuItem<String>(
                    value: loan.id,
                    child: Text('Loan ID: ${loan.id} - Amount: MWK ${loan['amount'].toStringAsFixed(2)}'),
                  );
                }).toList(),
              ),
            if (selectedLoan != null) ...[
              SizedBox(height: 16),
              Text(
                'Loan Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Table(
                border: TableBorder.all(color: Colors.grey),
                children: [
                  _buildTableRow('Loan Amount', 'MWK ${loanAmount.toStringAsFixed(2)}'),
                  _buildTableRow('Interest Rate', '${interestRate.toStringAsFixed(2)}%'),
                  _buildTableRow('Repayment Period', '${repaymentPeriod} months'),
                  _buildTableRow('Monthly Payment', 'MWK ${monthlyPayment.toStringAsFixed(2)}'),
                  _buildTableRow('Outstanding Balance', 'MWK ${outstandingLoanBalance.toStringAsFixed(2)}'),
                ],
              ),
              SizedBox(height: 16),
            ],
            if (transactionReference != null)
              Text(
                'Transaction Reference: $transactionReference',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            SizedBox(height: 16),
            TextField(
              controller: _paymentController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Payment Amount',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: Text('Upload Screenshot'),
                ),
                SizedBox(width: 10),
                if (_paymentScreenshot != null) Text('Screenshot added'),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _makePayment,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.black,
              ),
              child: Center(
                child: Text(
                  'Make Payment',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(value, style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
