import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'total_contributions_details_page.dart';

class TotalContributionsTile extends StatefulWidget {
  final String groupId;

  const TotalContributionsTile({
    required this.groupId,
  });

  @override
  _TotalContributionsTileState createState() => _TotalContributionsTileState();
}

class _TotalContributionsTileState extends State<TotalContributionsTile> {
  double totalMoneyCollectedForYear = 0.0; // For the total money collected for the year
  double totalInterest = 0.0;  // Only for confirmed loans, accrued monthly
  double remainingLoanBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchTotalContributionsData();
  }

  Future<void> _fetchTotalContributionsData() async {
    try {
      // Fetch seed money based on confirmed seed money payments
      QuerySnapshot seedMoneySnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('paymentType', isEqualTo: 'Seed Money')
          .where('status', isEqualTo: 'confirmed')
          .get();

      double totalSeedMoneyCollected = 0.0;
      for (var doc in seedMoneySnapshot.docs) {
        totalSeedMoneyCollected += (doc['amount'] as num).toDouble();
      }

      // Fetch loan repayments based on confirmed loans
      QuerySnapshot loanRepaymentsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('paymentType', isEqualTo: 'Loan Repayment')
          .where('status', isEqualTo: 'confirmed')
          .get();

      double totalLoanRepayments = 0.0;
      for (var doc in loanRepaymentsSnapshot.docs) {
        totalLoanRepayments += (doc['amount'] as num).toDouble();
      }

      // Fetch monthly contributions
      QuerySnapshot monthlyContributionsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('paymentType', isEqualTo: 'Monthly Contribution')
          .where('status', isEqualTo: 'confirmed')
          .get();

      double totalMonthlyContributions = 0.0;
      for (var doc in monthlyContributionsSnapshot.docs) {
        totalMonthlyContributions += (doc['amount'] as num).toDouble();
      }

      // Fetch quarterly payments
      QuerySnapshot quarterlyPaymentsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('paymentType', isEqualTo: 'Quarterly Payment')
          .where('status', isEqualTo: 'confirmed')
          .get();

      double totalQuarterlyPayments = 0.0;
      for (var doc in quarterlyPaymentsSnapshot.docs) {
        totalQuarterlyPayments += (doc['amount'] as num).toDouble();
      }

      // Fetch interest from confirmed loans
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      double totalInterestEarned = 0.0;
      if (groupSnapshot.exists) {
        var groupData = groupSnapshot.data() as Map<String, dynamic>;
        totalInterestEarned = (groupData['totalInterest'] ?? 0.0).toDouble();
        remainingLoanBalance = (groupData['remainingLoanBalance'] ?? 0.0).toDouble();
      }

      // Calculate total money collected
      double totalMoneyCollectedForYear = totalSeedMoneyCollected + totalLoanRepayments + totalMonthlyContributions + totalQuarterlyPayments + totalInterestEarned;

      setState(() {
        this.totalMoneyCollectedForYear = totalMoneyCollectedForYear;  // Use correct variable
        totalInterest = totalInterestEarned;
      });
    } catch (e) {
      print('Error fetching total contributions data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to detailed page for more info
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TotalContributionsDetailPage(groupId: widget.groupId),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Contributions Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildContributionDetail(
              context,
              title: 'Total Money Collected for the Year',
              value: 'MWK ${totalMoneyCollectedForYear.toStringAsFixed(2)}',  // Updated value
            ),
            SizedBox(height: 8),
            _buildContributionDetail(
              context,
              title: 'Total Interest (Confirmed Loans)',
              value: 'MWK ${totalInterest.toStringAsFixed(2)}',
            ),
            SizedBox(height: 8),
            _buildContributionDetail(
              context,
              title: 'Remaining Loan Balance',
              value: 'MWK ${remainingLoanBalance.toStringAsFixed(2)}',
            ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Tap to view more details',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionDetail(BuildContext context,
      {required String title, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
