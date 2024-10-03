import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'user_submit_payment_logic.dart';

class PaymentPage extends StatefulWidget {
  final String groupId;

  PaymentPage({required this.groupId});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _transactionReferenceController = TextEditingController();
  String? selectedPaymentType = 'Monthly Contribution';
  String? payerName = 'Unknown User';
  String? selectedMonth;
  File? _screenshotFile;
  double? fixedMonthlyAmount;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchGroupDetails();
  }

  Future<void> _fetchUserName() async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        setState(() {
          payerName = userDoc['name'] ?? 'Unknown User';
        });
      }
    }
  }

  Future<void> _fetchGroupDetails() async {
    // Fetch the fixed monthly amount from Firestore
    DocumentSnapshot groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();

    if (groupDoc.exists) {
      setState(() {
        fixedMonthlyAmount = groupDoc['fixedAmount']?.toDouble() ?? 0.0;
      });
    }
  }

  Future<void> _pickScreenshot() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _screenshotFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitPayment() async {
    double amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    String transactionReference = _transactionReferenceController.text.trim();

    try {
      final submitLogic = SubmitPaymentLogic(
        groupId: widget.groupId,
        payerName: payerName!,
        selectedPaymentType: selectedPaymentType!,
        transactionReference: transactionReference,
        amount: amount,
        selectedMonth: selectedMonth,
        screenshot: _screenshotFile,
      );
      await submitLogic.submitPayment();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment submitted successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Widget _buildPaymentTypeSection() {
    return DropdownButton<String>(
      value: selectedPaymentType,
      onChanged: (String? newValue) {
        setState(() {
          selectedPaymentType = newValue;
        });
      },
      items: <String>[
        'Monthly Contribution',
        'Loan Repayment',
        'Past Payment',
        'Penalty Fee',
      ].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _amountController,
          decoration: InputDecoration(labelText: 'Enter Amount (MWK)'),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 8),
        if (fixedMonthlyAmount != null) ...[
          Text('Fixed Monthly Contribution: MWK ${fixedMonthlyAmount!.toStringAsFixed(2)}'),
          TextButton(
            onPressed: () {
              setState(() {
                _amountController.text = fixedMonthlyAmount!.toStringAsFixed(2);
              });
            },
            child: Text('Click to Auto-Populate Amount'),
          ),
        ],
      ],
    );
  }

  Widget _buildTransactionReferenceSection() {
    return TextField(
      controller: _transactionReferenceController,
      decoration: InputDecoration(labelText: 'Enter Transaction Reference'),
    );
  }

  Widget _buildScreenshotButton() {
    return OutlinedButton.icon(
      onPressed: _pickScreenshot,
      icon: Icon(Icons.image),
      label: Text(_screenshotFile == null ? 'Upload Proof of Payment Screenshot' : 'Screenshot Selected'),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitPayment,
      child: Text('Submit Payment'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Make a Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPaymentTypeSection(),
            SizedBox(height: 20),
            _buildAmountSection(),
            SizedBox(height: 20),
            _buildTransactionReferenceSection(),
            SizedBox(height: 20),
            _buildScreenshotButton(),
            SizedBox(height: 20),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }
}
