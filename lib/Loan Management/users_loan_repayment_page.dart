import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // For image uploading
import 'dart:io'; // To handle file types

class LoanRepaymentPage extends StatefulWidget {
  final String groupId;
  final String userId;
  final double loanAmount;  // Confirmed loan amount
  final double interestRate; // Interest rate of the loan
  final int repaymentPeriod; // Loan repayment period in months
  final double outstandingBalance; // Outstanding loan balance to be updated

  LoanRepaymentPage({
    required this.groupId,
    required this.userId,
    required this.loanAmount,
    required this.interestRate,
    required this.repaymentPeriod,
    required this.outstandingBalance,
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

  @override
  void initState() {
    super.initState();
    _calculateLoanDetails();
    _fetchTransactionReference();
  }

  void _calculateLoanDetails() {
    double totalLoan = widget.loanAmount * (1 + widget.interestRate / 100);
    monthlyPayment = totalLoan / widget.repaymentPeriod;
    outstandingLoanBalance = widget.outstandingBalance;
    _paymentController.text = monthlyPayment.toStringAsFixed(2);
  }

  Future<void> _fetchTransactionReference() async {
    QuerySnapshot loanQuerySnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('loans')
        .where('userId', isEqualTo: widget.userId)
        .limit(1)
        .get();

    if (loanQuerySnapshot.docs.isNotEmpty) {
      setState(() {
        transactionReference = loanQuerySnapshot.docs.first['transactionReference'];
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

    if (paymentAmount > 0 && transactionReference != null) {
      try {
        QuerySnapshot loanQuerySnapshot = await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('loans')
            .where('userId', isEqualTo: widget.userId)
            .limit(1)
            .get();

        if (loanQuerySnapshot.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Loan document not found.'),
          ));
          return;
        }

        DocumentSnapshot loanDocSnapshot = loanQuerySnapshot.docs.first;
        String loanDocId = loanDocSnapshot.id;

        // Add payment record with status 'pending' for admin approval
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('payments')
            .add({
          'userId': widget.userId,
          'paymentType': 'Loan Repayment',
          'amount': paymentAmount,
          'status': 'pending', // Payment pending approval
          'paymentDate': Timestamp.now(),
          'referenceNumber': transactionReference,
          'screenshot': _paymentScreenshot != null ? await _uploadScreenshot() : null,
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Payment made and is pending admin approval.'),
        ));
      } catch (e) {
        print('Error making payment: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Payment failed. Please try again.'),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill in a valid payment amount.'),
      ));
    }
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
            Text(
              'Loan Details',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey),
              children: [
                _buildTableRow('Loan Amount', 'MWK ${widget.loanAmount.toStringAsFixed(2)}'),
                _buildTableRow('Interest Rate', '${widget.interestRate.toStringAsFixed(2)}%'),
                _buildTableRow('Repayment Period', '${widget.repaymentPeriod} months'),
                _buildTableRow('Monthly Payment', 'MWK ${monthlyPayment.toStringAsFixed(2)}'),
                _buildTableRow('Outstanding Balance', 'MWK ${outstandingLoanBalance.toStringAsFixed(2)}'),
              ],
            ),
            SizedBox(height: 20),
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
