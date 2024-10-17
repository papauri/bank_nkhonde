import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Loan Management/loan_services_page.dart';
import 'member_list_tile.dart';
import 'user_payment_page.dart'; // Import the new payment page
import 'user_payment_details_page.dart'; // Import for navigating to payment details
import 'seed_money_payment_page.dart'; // Import the Seed Money Payment Page

class GroupDetailsPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String userId;

  GroupDetailsPage({
    required this.groupId,
    required this.groupName,
    required this.userId,
  });

  @override
  _GroupDetailsPageState createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  List<Map<String, dynamic>> userLoans = [];
  double amountOwedForMonth = 0.0;
  double amountPaidForMonth = 0.0;
  double fixedAmount = 0.0;
  double seedMoneyAmount = 0.0;
  double seedMoneyPaid = 0.0;
  List<Map<String, dynamic>> members = [];
  double pendingPayments = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
    _fetchUserFinancialData();
  }

  Future<void> _fetchGroupData() async {
    try {
      DocumentSnapshot groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupDoc.exists) {
        var data = groupDoc.data() as Map<String, dynamic>;
        setState(() {
          fixedAmount = (data['fixedAmount'] ?? 0.0).toDouble();
          seedMoneyAmount = (data['seedMoney'] ?? 0.0).toDouble();
          members = List<Map<String, dynamic>>.from(data['members'] ?? []);
        });
      }
    } catch (e) {
      print('Error fetching group data: $e');
    }
  }

  Future<void> _fetchUserFinancialData() async {
    try {
      QuerySnapshot confirmedPaymentsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('userId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'confirmed')
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

      double totalOwed = fixedAmount - totalPaid;
      if (totalOwed < 0) totalOwed = 0.0;

      setState(() {
        amountPaidForMonth = totalPaid;
        amountOwedForMonth = totalOwed;
        seedMoneyPaid = totalSeedPaid;
      });
    } catch (e) {
      print('Error fetching user financial data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.groupName,
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchGroupData();
          await _fetchUserFinancialData();
        },
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          children: [
            Text(
              'Financial Overview',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),

            _buildMonthlyFinancialOverview(),
            SizedBox(height: 16),

            _buildSeedMoneyOverview(),
            SizedBox(height: 16),

            // Loan Services Tile
            _buildLoanServicesTile(),
            SizedBox(height: 16),

            // Make Payment button
            _buildPaymentButton(Colors.blueGrey[800]!),
            SizedBox(height: 16),

            // Group Members section at the bottom
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

  Widget _buildLoanServicesTile() {
    return GestureDetector(
      onTap: () {
        // Navigate to Loan Services Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoanServicesPage(
              groupId: widget.groupId,
              userId: widget.userId,
            ),
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
                  'Loan Services',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage loans, apply for new loans',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            Icon(Icons.arrow_forward, color: Colors.blueGrey[800]),
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
            builder: (context) => PaymentDetailsPage(
                groupId: widget.groupId, userId: widget.userId),
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
