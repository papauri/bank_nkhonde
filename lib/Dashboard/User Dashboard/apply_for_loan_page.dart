import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApplyForLoanPage extends StatelessWidget {
  final String groupId;

  ApplyForLoanPage({required this.groupId});

  final TextEditingController _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Apply for Loan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: 'Loan Amount'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _applyForLoan(context);
              },
              child: Text('Submit Loan Application'),
            ),
          ],
        ),
      ),
    );
  }

  void _applyForLoan(BuildContext context) async {
    final String loanAmount = _amountController.text.trim();

    if (loanAmount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a loan amount')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('loans')
          .add({
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'amount': double.parse(loanAmount),
        'status': 'pending',
        'appliedAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loan application submitted!')),
      );

      Navigator.pop(context); // Go back to the previous page
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to apply for loan. Please try again.')),
      );
    }
  }
}
