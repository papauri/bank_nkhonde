import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentPage extends StatefulWidget {
  final String groupId; // Group ID passed from the previous page
  PaymentPage({required this.groupId});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TextEditingController _amountController = TextEditingController();
  String? selectedPaymentType = 'Monthly Contribution';
  String? payerName = 'Unknown User'; // Default if the name is not fetched

  @override
  void initState() {
    super.initState();
    _fetchUserName(); // Fetch the user's name on page load
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
          payerName = userDoc['name'] ?? 'Unknown User'; // Fetch the user's name
        });
      }
    }
  }

  Future<void> _submitPayment() async {
    String amount = _amountController.text.trim();
    if (amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    try {
      // Submit payment under the 'payments' collection of the group
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .add({
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'payerName': payerName, // Include the payer's name
        'amount': double.parse(amount),
        'paymentType': selectedPaymentType,
        'status': 'pending', // Initial status set to 'pending'
        'paymentDate': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment submitted successfully!')),
      );
      Navigator.pop(context); // Go back to the previous page
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit payment. Please try again.')),
      );
    }
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
            DropdownButton<String>(
              value: selectedPaymentType,
              onChanged: (String? newValue) {
                setState(() {
                  selectedPaymentType = newValue!;
                });
              },
              items: <String>[
                'Monthly Contribution',
                'Loan Repayment',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: 'Enter Amount (MWK)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitPayment,
              child: Text('Submit Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
