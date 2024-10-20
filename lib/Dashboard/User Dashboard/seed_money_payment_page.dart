import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class SeedMoneyPaymentPage extends StatefulWidget {
  final String groupId;

  SeedMoneyPaymentPage({required this.groupId});

  @override
  _SeedMoneyPaymentPageState createState() => _SeedMoneyPaymentPageState();
}

class _SeedMoneyPaymentPageState extends State<SeedMoneyPaymentPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _transactionReferenceController = TextEditingController();
  String? payerName = 'Unknown User';
  File? _screenshotFile;
  double? seedMoneyAmount;
  double? totalOwed;
  bool _isSubmitting = false;
  String? selectedReference;

  @override
  void initState() {
    super.initState();
    _fetchData();
    final currentYear = DateFormat('yyyy').format(DateTime.now());
    final currentMonth = DateFormat('MMMM').format(DateTime.now());
    selectedReference = 'Seed Money - $currentMonth $currentYear'; // Initialize selectedReference
  }

  Future<void> _fetchData() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      final groupDoc = await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get();
      final confirmedPaymentsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('userId', isEqualTo: currentUserId)
          .where('paymentType', isEqualTo: 'Seed Money')
          .where('status', isEqualTo: 'confirmed')
          .get();

      double totalPaid = 0.0;
      for (var doc in confirmedPaymentsSnapshot.docs) {
        totalPaid += (doc['amount'] as num).toDouble();
      }

      setState(() {
        payerName = userDoc['name'] ?? 'Unknown User';
        seedMoneyAmount = groupDoc['seedMoney']?.toDouble() ?? 0.0;
        totalOwed = (seedMoneyAmount! - totalPaid) > 0 ? (seedMoneyAmount! - totalPaid) : 0.0;
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
    if (_validateInputs()) {
      setState(() {
        _isSubmitting = true;
      });
      try {
        await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).collection('payments').add({
          'userId': FirebaseAuth.instance.currentUser?.uid,
          'amount': double.parse(_amountController.text.trim()),
          'paymentType': 'Seed Money',
          'transactionReference': _transactionReferenceController.text.trim(),
          'status': 'pending',
          'paymentDate': Timestamp.now(),
          'payerName': payerName, // Add payerName to the payment record
          'screenshotUrl': null, // Add upload logic if needed
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment submitted successfully!')));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit payment. Try again.')));
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  bool _validateInputs() {
    if (_amountController.text.trim().isEmpty || double.tryParse(_amountController.text.trim()) == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a valid amount')));
      return false;
    }
    if (_transactionReferenceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a transaction reference')));
      return false;
    }
    if (_screenshotFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please upload a screenshot of the payment')));
      return false;
    }
    return true;
  }

  Future<List<Map<String, dynamic>>> _fetchUserPayments() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final paymentSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('payments')
        .where('userId', isEqualTo: currentUserId)
        .where('paymentType', isEqualTo: 'Seed Money')
        .get();

    return paymentSnapshot.docs.map((doc) {
      return {
        'amount': doc['amount'],
        'paymentDate': (doc['paymentDate'] as Timestamp).toDate(),
        'status': doc['status'],
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Seed Money Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAmountSection(),
            SizedBox(height: 20),
            _buildTransactionReferenceSection(),
            SizedBox(height: 20),
            _buildScreenshotButton(),
            SizedBox(height: 20),
            _buildSubmitButton(),
            SizedBox(height: 20),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchUserPayments(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final userPayments = snapshot.data!;
                return _buildUserPaymentsTable(userPayments);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection() {
    final isOwed = totalOwed != null && totalOwed! > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (totalOwed != null)
          Text('Total Owed: MWK ${totalOwed!.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        TextField(
          controller: _amountController,
          decoration: InputDecoration(labelText: 'Enter Amount (MWK)'),
          keyboardType: TextInputType.number,
          enabled: isOwed,
        ),
        TextButton(
          onPressed: isOwed
              ? () {
                  setState(() {
                    _amountController.text = totalOwed!.toStringAsFixed(2);
                  });
                }
              : null,
          child: Text('Auto-Populate Total Owed'),
        ),
        if (!isOwed)
          Text(
            'No balance owed for this year. You have paid the full amount.',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _buildTransactionReferenceSection() {
    final currentYear = DateFormat('yyyy').format(DateTime.now());
    final currentMonth = DateFormat('MMMM').format(DateTime.now());

    List<String> referenceOptions = [
      'Seed Money - $currentMonth $currentYear',
      'Seed Money - Custom',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Transaction Reference:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        DropdownButton<String>(
          value: selectedReference,
          onChanged: (totalOwed != null && totalOwed! > 0)
              ? (String? newValue) {
                  setState(() {
                    selectedReference = newValue;

                    // If 'Custom' is selected, show the custom reference text field
                    if (newValue != null && newValue == 'Seed Money - Custom') {
                      _transactionReferenceController.clear();
                    } else {
                      _transactionReferenceController.text = newValue!;
                    }
                  });
                }
              : null,
          items: referenceOptions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        if (selectedReference == 'Seed Money - Custom') ...[
          SizedBox(height: 8),
          TextField(
            controller: _transactionReferenceController,
            decoration: InputDecoration(labelText: 'Enter Custom Reference'),
            enabled: totalOwed != null && totalOwed! > 0,
          ),
        ],
      ],
    );
  }

  Widget _buildScreenshotButton() {
    final isOwed = totalOwed != null && totalOwed! > 0;
    return OutlinedButton.icon(
      onPressed: isOwed ? _pickScreenshot : null,
      icon: Icon(Icons.image),
            label: Text(_screenshotFile == null ? 'Upload Proof of Payment Screenshot' : 'Screenshot Selected'),
    );
  }

  Widget _buildSubmitButton() {
    final isOwed = totalOwed != null && totalOwed! > 0;
    return _isSubmitting
        ? Center(child: CircularProgressIndicator())
        : ElevatedButton(
            onPressed: isOwed ? _submitPayment : null,
            child: Text(isOwed ? 'Submit Payment' : 'No Payment Needed'),
          );
  }

  Widget _buildUserPaymentsTable(List<Map<String, dynamic>> payments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: Colors.grey, width: 1),
          columnWidths: {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[300]),
              children: [
                _buildTableCell('Date', isHeader: true),
                _buildTableCell('Amount', isHeader: true),
                _buildTableCell('Status', isHeader: true),
              ],
            ),
            ...payments.map((payment) {
              String paymentDateFormatted = DateFormat('dd MMM yyyy').format(payment['paymentDate']);
              return TableRow(
                children: [
                  _buildTableCell(paymentDateFormatted),
                  _buildTableCell('MWK ${payment['amount'].toStringAsFixed(2)}'),
                  _buildTableCell(payment['status']),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

