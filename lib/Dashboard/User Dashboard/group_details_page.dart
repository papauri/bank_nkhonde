import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'financial_overview.dart';

class GroupDetailsPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  GroupDetailsPage({required this.groupId, required this.groupName});

  @override
  _GroupDetailsPageState createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  double totalContribution = 0.0;
  double outstandingLoans = 0.0;
  double availableFunds = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchGroupFinancialData();
  }

  Future<void> _fetchGroupFinancialData() async {
    DocumentSnapshot groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();

    if (groupDoc.exists) {
      setState(() {
        totalContribution = groupDoc['totalContribution'] ?? 0.0;
        outstandingLoans = groupDoc['outstandingLoans'] ?? 0.0;
        availableFunds = groupDoc['availableFunds'] ?? 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          FinancialOverview(
            totalContribution: totalContribution,
            outstandingLoans: outstandingLoans,
            availableFunds: availableFunds,
            groupId: widget.groupId, // Pass the groupId to FinancialOverview
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Logic to apply for loan or other group actions
            },
            child: Text('Apply for Loan'),
          ),
        ],
      ),
    );
  }
}
