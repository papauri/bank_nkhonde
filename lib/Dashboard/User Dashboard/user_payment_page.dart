import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'user_submit_payment_logic.dart';
import 'package:intl/intl.dart';  // For date formatting

class PaymentPage extends StatefulWidget {
  final String groupId;

  PaymentPage({required this.groupId});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _customReferenceController = TextEditingController();
  String? selectedPaymentType = 'Monthly Contribution';
  String? payerName = 'Unknown User';
  File? _screenshotFile;
  double? fixedMonthlyAmount;
  double? totalOwed;
  bool _isSubmitting = false;
  String? selectedReference;

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
        _calculateTotalOwed();  // Calculate total owed after fetching group details
      });
    }
  }

  Future<void> _calculateTotalOwed() async {
    try {
      String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

      // Fetch confirmed payments for the current month only (amount paid by the user)
      QuerySnapshot confirmedPaymentsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('userId', isEqualTo: currentUserId) // Only fetch this user's payments
          .where('status', isEqualTo: 'confirmed') // Only fetch confirmed payments
          .where('paymentType', isEqualTo: 'Monthly Contribution') // Only fetch monthly contributions
          .get();

      double totalPaid = 0.0;
      for (var doc in confirmedPaymentsSnapshot.docs) {
        totalPaid += (doc['amount'] as num).toDouble();
      }

      // Calculate total owed for monthly contribution
      setState(() {
        totalOwed = (fixedMonthlyAmount != null && totalPaid != null) 
          ? (fixedMonthlyAmount! - totalPaid)
          : 0.0;
      });
    } catch (e) {
      print('Error calculating total owed: $e');
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
    double? amount = double.tryParse(_amountController.text.trim());
    String transactionReference = selectedReference == 'Custom'
        ? _customReferenceController.text.trim()
        : selectedReference ?? '';

    // Check if all mandatory fields are filled
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (transactionReference.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a transaction reference')),
      );
      return;
    }

    if (_screenshotFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload a screenshot of the payment')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final submitLogic = SubmitPaymentLogic(
        groupId: widget.groupId,
        payerName: payerName!,
        selectedPaymentType: selectedPaymentType!,
        transactionReference: transactionReference,
        amount: amount,
        screenshot: _screenshotFile,
      );
      await submitLogic.submitPayment();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment submitted successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit payment. Please try again.')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildPaymentTypeSection() {
    return DropdownButton<String>(
      value: selectedPaymentType,
      onChanged: (String? newValue) {
        setState(() {
          selectedPaymentType = newValue;
          _calculateTotalOwed(); // Recalculate total owed based on selected payment type
        });
      },
      items: <String>[
        'Monthly Contribution',
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
        if (totalOwed != null)
          Text(
            'Total Owed: MWK ${totalOwed!.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        SizedBox(height: 8),
        if (selectedPaymentType == 'Monthly Contribution' && fixedMonthlyAmount != null)
          Text(
            'Monthly Contribution: MWK ${fixedMonthlyAmount!.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        SizedBox(height: 8),
        TextField(
          controller: _amountController,
          decoration: InputDecoration(labelText: 'Enter Amount (MWK)'),
          keyboardType: TextInputType.number,
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _amountController.text = totalOwed?.toStringAsFixed(2) ?? '0.00'; // Auto-populate with valid value
            });
          },
          child: Text('Auto-Populate Total Owed'),
        ),
        SizedBox(height: 8),
      ],
    );
  }
  Widget _buildTransactionReferenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Transaction Reference',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        DropdownButton<String>(
          value: selectedReference,
          hint: Text('Select a reference or enter custom'),
          onChanged: (String? newValue) {
            setState(() {
              selectedReference = newValue;
              if (selectedReference != 'Custom') {
                _customReferenceController.clear(); // Clear custom reference when a predefined one is selected
              }
            });
          },
          items: <String>[
            'Payment for ${DateFormat('MMMM yyyy').format(DateTime.now())}', // Dynamic current month reference
            'Loan Repayment',
            'Penalty Payment',
            'Custom', // Option for entering a custom reference
          ].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        if (selectedReference == 'Custom')
          TextField(
            controller: _customReferenceController,
            decoration: InputDecoration(labelText: 'Enter Custom Transaction Reference'),
          ),
        SizedBox(height: 8),
      ],
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
    return _isSubmitting
        ? Center(child: CircularProgressIndicator())
        : ElevatedButton(
            onPressed: _submitPayment,
            child: Text('Submit Payment'),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Make a Payment')),
      body: SingleChildScrollView( // Wrap in SingleChildScrollView to prevent overflow
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPaymentTypeSection(),
              SizedBox(height: 20),
              _buildAmountSection(),
              SizedBox(height: 20),
              _buildTransactionReferenceSection(), // Updated section
              SizedBox(height: 20),
              _buildScreenshotButton(),
              SizedBox(height: 20),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }
}
