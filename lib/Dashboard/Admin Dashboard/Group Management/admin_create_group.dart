import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupCreationPage extends StatefulWidget {
  @override
  _GroupCreationPageState createState() => _GroupCreationPageState();
}

class _GroupCreationPageState extends State<GroupCreationPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _seedMoneyController = TextEditingController();
  final TextEditingController _interestRateController = TextEditingController();
  final TextEditingController _fixedAmountController = TextEditingController();
  final TextEditingController _loanPenaltyController = TextEditingController();  // Loan penalty field
  final TextEditingController _monthlyPenaltyController = TextEditingController();  // Monthly contribution penalty field
  String errorMessage = '';

  void _createGroup() async {
    String groupName = _groupNameController.text.trim();
    String seedMoney = _seedMoneyController.text.trim();
    String interestRate = _interestRateController.text.trim();
    String fixedAmount = _fixedAmountController.text.trim();
    String loanPenalty = _loanPenaltyController.text.trim();  // Get loan penalty
    String monthlyPenalty = _monthlyPenaltyController.text.trim();  // Get monthly penalty

    if (groupName.isEmpty || seedMoney.isEmpty || interestRate.isEmpty || fixedAmount.isEmpty) {
      setState(() {
        errorMessage = 'Please fill in all fields.';
      });
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('groups').add({
        'groupName': groupName,
        'seedMoney': double.parse(seedMoney),
        'interestRate': double.parse(interestRate),
        'fixedAmount': double.parse(fixedAmount),  // Adding fixed amount
        'admin': FirebaseAuth.instance.currentUser!.uid,
        'members': [], // Group starts with no members
        'totalContributions': 0.0, // Initialize total contributions
        'loanPenalty': loanPenalty.isNotEmpty ? double.parse(loanPenalty) : 0.0, // Apply loan penalty if filled
        'monthlyPenalty': monthlyPenalty.isNotEmpty ? double.parse(monthlyPenalty) : 0.0, // Apply monthly penalty if filled
        'createdAt': Timestamp.now(), // Add creation timestamp
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group created successfully!')),
      );

      Navigator.pop(context); // Go back to previous screen after creating the group
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to create group. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create a New Group'),
        backgroundColor: Colors.teal[800], // Adding a background color for styling
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _groupNameController,
                decoration: InputDecoration(labelText: 'Group Name'),
              ),
              TextField(
                controller: _seedMoneyController,
                decoration: InputDecoration(labelText: 'Seed Money (MWK)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _interestRateController,
                decoration: InputDecoration(labelText: 'Interest Rate (%)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _fixedAmountController,
                decoration: InputDecoration(labelText: 'Fixed Monthly Contribution (MWK)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _loanPenaltyController,
                decoration: InputDecoration(labelText: 'Loan Late Payment Penalty (%)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _monthlyPenaltyController,
                decoration: InputDecoration(labelText: 'Monthly Contribution Late Penalty (%)'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createGroup,
                child: Text('Create Group'),
              ),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
