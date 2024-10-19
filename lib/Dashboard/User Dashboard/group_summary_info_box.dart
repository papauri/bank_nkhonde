import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GroupSummaryInfoBox extends StatefulWidget {
  final String groupId;

  GroupSummaryInfoBox({required this.groupId});

  @override
  _GroupSummaryInfoBoxState createState() => _GroupSummaryInfoBoxState();
}

class _GroupSummaryInfoBoxState extends State<GroupSummaryInfoBox> {
  double totalReceivedForYear = 0.0;
  double totalReceivedForMonth = 0.0;
  double confirmedLoansForMonth = 0.0;
  double moneyRemainingInPool = 0.0;
  String currentYear = '';
  String currentMonth = '';

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    currentYear = DateFormat('yyyy').format(now); // Dynamic year
    currentMonth = DateFormat('MMMM').format(now); // Dynamic month
    _fetchGroupFinancialData();
  }

  Future<void> _fetchGroupFinancialData() async {
    try {
      DateTime now = DateTime.now();
      int currentYearInt = now.year;

      // Fetch confirmed payments for the current group
      QuerySnapshot paymentsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('status', isEqualTo: 'confirmed')
          .get();

      QuerySnapshot loansSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('loans')
          .where('status', isEqualTo: 'approved')
          .get();

      double yearTotal = 0.0;
      double monthTotal = 0.0;
      double confirmedLoansForMonth = 0.0;
      double moneyRemainingInPool = 0.0;

      // Iterate over all confirmed payments to calculate totals
      for (var doc in paymentsSnapshot.docs) {
        DateTime paymentDate = (doc['paymentDate'] as Timestamp).toDate();
        double paymentAmount = (doc['amount'] as num).toDouble();
        String paymentType = doc['paymentType'] ?? '';

        // Check if the payment is from the current year
        if (paymentDate.year == currentYearInt) {
          if (paymentType == 'Seed Money' || paymentType == 'Quarterly Payment' ||
              paymentType == 'Loan Repayment' || paymentType == 'Monthly Contribution' ||
              paymentType == 'Penalty Fee') {
            yearTotal += paymentAmount;
          }
        }

        // Check if the payment is from the current month
        if (paymentDate.month == now.month && paymentDate.year == currentYearInt) {
          monthTotal += paymentAmount;

          // Only add to pool if it's not seed money or quarterly payment
          if (paymentType == 'Monthly Contribution' || paymentType == 'Loan Repayment' || paymentType == 'Interest Earned') {
            moneyRemainingInPool += paymentAmount;
          }
        }
      }

      // Calculate confirmed loans for the month
      for (var loanDoc in loansSnapshot.docs) {
        DateTime loanApprovalDate = (loanDoc['approvedAt'] as Timestamp).toDate();
        double loanAmount = (loanDoc['amount'] as num).toDouble();

        if (loanApprovalDate.month == now.month && loanApprovalDate.year == currentYearInt) {
          confirmedLoansForMonth += loanAmount;
        }

        // Subtract confirmed loans from the pool for money available to borrow
        moneyRemainingInPool -= loanAmount;
      }

      // Now, store this data into Firestore under the groupFinancialSummary collection
      DocumentReference summaryDocRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('groupFinancialSummary')
          .doc(currentYearInt.toString());

      // Check if the document exists
      DocumentSnapshot summaryDoc = await summaryDocRef.get();

      if (summaryDoc.exists) {
        // Update the existing document
        await summaryDocRef.update({
          'totalReceivedForYear': yearTotal,
          'totalReceivedForMonth': monthTotal,
          'confirmedLoansForMonth': confirmedLoansForMonth,
          'moneyRemainingInPool': moneyRemainingInPool,
          'lastUpdated': now,
        });
      } else {
        // Create a new document for the current year
        await summaryDocRef.set({
          'totalReceivedForYear': yearTotal,
          'totalReceivedForMonth': monthTotal,
          'confirmedLoansForMonth': confirmedLoansForMonth,
          'moneyRemainingInPool': moneyRemainingInPool,
          'lastUpdated': now,
        });
      }

      setState(() {
        totalReceivedForYear = yearTotal;
        totalReceivedForMonth = monthTotal;
        this.confirmedLoansForMonth = confirmedLoansForMonth;
        this.moneyRemainingInPool = moneyRemainingInPool;
      });
    } catch (e) {
      print('Error fetching financial data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            'Group Financial Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          _buildSummaryRow('Total Received in $currentYear', 'MWK ${totalReceivedForYear.toStringAsFixed(2)}'),
          SizedBox(height: 8),
          _buildSummaryRow('Total Received in $currentMonth', 'MWK ${totalReceivedForMonth.toStringAsFixed(2)}'),
          SizedBox(height: 8),
          _buildSummaryRow('Confirmed Loans for the Month', 'MWK ${confirmedLoansForMonth.toStringAsFixed(2)}'),
          SizedBox(height: 8),
          _buildSummaryRow('Money Remaining in Pool', 'MWK ${moneyRemainingInPool.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.black)),
        Text(value, style: TextStyle(fontSize: 16, color: Colors.black)),
      ],
    );
  }
}
