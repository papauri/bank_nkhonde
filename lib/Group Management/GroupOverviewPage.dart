import 'package:bank_nkhonde/Payment%20Management/PendingLoansPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Payment Management/loan_management_page.dart';
import '../Payment Management/payment_management_page.dart';
import '../Account Management/member_management_page.dart';

class GroupOverviewPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  GroupOverviewPage({required this.groupId, required this.groupName});

  @override
  _GroupOverviewPageState createState() => _GroupOverviewPageState();
}

class _GroupOverviewPageState extends State<GroupOverviewPage> {
  double totalFunds = 0.0;
  double totalContributions = 0.0;
  double pendingLoanAmount = 0.0;
  int pendingLoanApplicants = 0;
  double fixedAmount = 0.0; // Fixed monthly contribution set by admin
  double interestRate = 0.0;
  double seedMoney = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
  }

  Future<void> _fetchGroupData() async {
    try {
      // Fetch the group document from Firestore
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupSnapshot.exists) {
        final data = groupSnapshot.data() as Map<String, dynamic>;

        setState(() {
          // Fetch seedMoney, interestRate, and fixedAmount from Firestore document
          seedMoney = (data['seedMoney']?.toDouble() ?? 0.0);
          interestRate = (data['interestRate']?.toDouble() ?? 0.0);
          fixedAmount = (data['fixedAmount']?.toDouble() ?? 0.0);
          totalContributions = (data['totalContributions']?.toDouble() ?? 0.0);

          // You can calculate totalFunds as:
          totalFunds = seedMoney + totalContributions - pendingLoanAmount;
        });
      }

      // Fetch pending loans for the group
      QuerySnapshot loanSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('loans')
          .where('status', isEqualTo: 'pending')
          .get();

      double totalPendingAmount = 0.0;
      int loanApplicants = loanSnapshot.docs.length;

      for (var loan in loanSnapshot.docs) {
        totalPendingAmount += loan['amount']?.toDouble() ?? 0.0;
      }

      setState(() {
        pendingLoanAmount = totalPendingAmount;
        pendingLoanApplicants = loanApplicants;
      });
    } catch (e) {
      print("Failed to fetch group data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch group data.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Overview: ${widget.groupName}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.0),
              children: [
                _buildOverviewCard('Total Funds Available', 'MWK $totalFunds'),
                // In the GroupOverviewPage, make the Pending Loans clickable
                _buildOverviewCard(
                  'Pending Loans',
                  'MWK $pendingLoanAmount\nApplicants: $pendingLoanApplicants',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PendingLoansPage(
                          groupId: widget.groupId,
                          groupName: widget.groupName,
                        ),
                      ),
                    );
                  },
                ),
                _buildOverviewCard('Total Contributions', 'MWK $totalContributions'),
                _buildOverviewCard('Seed Money', 'MWK $seedMoney'),
                _buildOverviewCard('Interest Rate', '$interestRate%'),
                _buildOverviewCard('Fixed Monthly Contribution', 'MWK $fixedAmount'),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _showEditFixedAmountDialog(); // Edit fixed amount button
                  },
                  child: Text('Edit Fixed Monthly Contribution'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MemberManagementPage(
                          groupId: widget.groupId,
                          groupName: widget.groupName,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.group),
                  label: Text('View Members'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoanManagementPage(
                          groupId: widget.groupId,
                          groupName: widget.groupName,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.monetization_on),
                  label: Text('Manage Loans'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentManagementPage(
                          groupId: widget.groupId,
                          groupName: widget.groupName,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.payment),
                  label: Text('Manage Payments'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, {Function()? onTap}) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onTap, // Make the card clickable
      ),
    );
  }

  // Method to show a dialog for editing the fixed amount
  void _showEditFixedAmountDialog() {
    final TextEditingController _fixedAmountController =
        TextEditingController(text: fixedAmount.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Fixed Monthly Contribution'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _fixedAmountController,
                decoration: InputDecoration(labelText: 'Fixed Amount (MWK)'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              Text(
                'Warning: Changing the fixed amount will affect all upcoming member contributions. Please ensure this change is communicated clearly to group members.',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateFixedAmount(_fixedAmountController.text);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Method to update the fixed amount in Firestore
  void _updateFixedAmount(String newFixedAmount) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
        'fixedAmount': double.parse(newFixedAmount),
      });

      setState(() {
        fixedAmount = double.parse(newFixedAmount);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Fixed monthly contribution updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update fixed amount. Try again.')),
      );
    }
  }
}
