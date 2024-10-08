import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'member_list_tile.dart';
import 'user_payment_page.dart'; // Import the new payment page
import 'user_payment_details_page.dart'; // Import for navigating to payment details
import 'seed_money_payment_page.dart'; // Import the Seed Money Payment Page

class GroupDetailsPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String userId; // Add userId for fetching only this user's data

  GroupDetailsPage({required this.groupId, required this.groupName, required this.userId});

  @override
  _GroupDetailsPageState createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  double amountOwedForMonth = 0.0;
  double amountPaidForMonth = 0.0; // New field for amount paid
  double fixedAmount = 0.0; // Group's default fixed amount
  double seedMoneyAmount = 0.0; // Seed money for the group
  double seedMoneyPaid = 0.0; // Seed money paid by the user
  List<Map<String, dynamic>> members = [];
  double pendingPayments = 0.0; // Field for pending payments

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
    _fetchUserFinancialData(); // Fetch user-specific financial data
  }

  Future<void> _fetchGroupData() async {
    try {
      // Fetch the group's details, including fixedAmount for contributions
      DocumentSnapshot groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupDoc.exists) {
        var data = groupDoc.data() as Map<String, dynamic>;
        setState(() {
          fixedAmount = (data['fixedAmount'] ?? 0.0).toDouble(); // Fetch the fixedAmount from Firestore
          seedMoneyAmount = (data['seedMoney'] ?? 0.0).toDouble(); // Fetch the seedMoney from Firestore
          members = List<Map<String, dynamic>>.from(data['members'] ?? []);
        });
      }
    } catch (e) {
      print('Error fetching group data: $e');
    }
  }

  Future<void> _fetchUserFinancialData() async {
    try {
      // Fetch confirmed payments (amount paid by the user)
      QuerySnapshot confirmedPaymentsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('userId', isEqualTo: widget.userId) // Only fetch this user's payments
          .where('status', isEqualTo: 'confirmed') // Only fetch confirmed payments
          .get();

      double totalPaid = 0.0;
      double totalSeedPaid = 0.0;
      for (var doc in confirmedPaymentsSnapshot.docs) {
        if (doc['paymentType'] == 'Seed Money') {
          totalSeedPaid += (doc['amount'] as num).toDouble();
        } else {
          totalPaid += (doc['amount'] as num).toDouble();
        }
      }

      // Fetch pending payments (amount not yet confirmed)
      QuerySnapshot pendingPaymentsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('userId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'pending') // Only fetch pending payments
          .get();

      double totalPending = 0.0;
      for (var doc in pendingPaymentsSnapshot.docs) {
        totalPending += (doc['amount'] as num).toDouble();
      }

      // Calculate amount owed as the default fixed amount minus confirmed amount paid
      double totalOwed = fixedAmount - totalPaid;
      if (totalOwed < 0) totalOwed = 0.0; // Ensure no negative values for owed amount

      setState(() {
        amountPaidForMonth = totalPaid;
        amountOwedForMonth = totalOwed;
        pendingPayments = totalPending;
        seedMoneyPaid = totalSeedPaid;
      });
    } catch (e) {
      print('Error fetching user financial data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.blueGrey[800]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.groupName,
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black), // Ensure icons match the theme
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchGroupData();
          await _fetchUserFinancialData();
        },
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          children: [
            // Financial Overview Section
            Text(
              'Financial Overview',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            _buildMonthlyFinancialOverview(), // Updated financial overview
            SizedBox(height: 16),
            _buildSeedMoneyOverview(), // Seed money overview tile

            if (pendingPayments > 0) ...[
              SizedBox(height: 16),
              _buildPendingPaymentsTile(),
            ],

            SizedBox(height: 32),

            // Apply for Loan Button
            _buildApplyForLoanButton(primaryColor),

            SizedBox(height: 16), // Adjusted spacing

            // Payment Button
            _buildPaymentButton(primaryColor), // Payment button added here

            SizedBox(height: 32),

            // Members Section
            Text(
              'Group Members',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildMembersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyFinancialOverview() {
    return GestureDetector(
      onTap: () {
        // Navigate to user payment details page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentDetailsPage(groupId: widget.groupId, userId: widget.userId),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount Owed for the Month',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'MWK ${amountOwedForMonth.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, color: Colors.orange),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Amount Paid',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'MWK ${amountPaidForMonth.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeedMoneyOverview() {
    double seedMoneyBalance = seedMoneyAmount - seedMoneyPaid;
    return GestureDetector(
      onTap: () {
        // Navigate to Seed Money Payment Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SeedMoneyPaymentPage(groupId: widget.groupId),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seed Money Payment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'MWK ${seedMoneyPaid.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, color: Colors.green),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Balance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'MWK ${seedMoneyBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    color: seedMoneyBalance > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingPaymentsTile() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Payments',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'MWK ${pendingPayments.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 18, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyForLoanButton(Color primaryColor) {
    return ElevatedButton(
      onPressed: () {
        // Navigate to loan application page or show a dialog
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        'Apply for Loan',
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }

  Widget _buildPaymentButton(Color primaryColor) {
    return ElevatedButton(
      onPressed: () {
        // Navigate to PaymentPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentPage(groupId: widget.groupId),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        'Make a Payment',
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }

  Widget _buildMembersList() {
    if (members.isEmpty) {
      return Center(child: Text('No members found.'));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: members.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        final member = members[index];
        return MemberListTile(
          name: member['name'] ?? 'Unnamed',
          profilePictureUrl: member['profilePicture'],
          memberId: member['userId'],
        );
      },
    );
  }
}
