import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TotalContributionsDetailPage extends StatefulWidget {
  final String groupId;

  TotalContributionsDetailPage({required this.groupId});

  @override
  _TotalContributionsDetailPageState createState() => _TotalContributionsDetailPageState();
}

class _TotalContributionsDetailPageState extends State<TotalContributionsDetailPage> {
  double totalSeedMoney = 0.0;
  double totalInterest = 0.0;  // Total interest applies only to confirmed loans
  double loanRepayments = 0.0;
  double quarterlyPayments = 0.0;
  double penaltiesPaid = 0.0;
  double approvedLoansForMonth = 0.0;
  double remainingLoanBalance = 0.0;
  double fixedInterestRate = 0.0; // Assuming this is fixed and set during loan creation

  List<Map<String, dynamic>> membersContributions = [];

  @override
  void initState() {
    super.initState();
    _fetchGroupFinancialData();
    _fetchMembersContributions();
  }

  Future<void> _fetchGroupFinancialData() async {
    try {
      double totalSeedMoneyCollected = 0.0;
      double totalLoanRepayments = 0.0;
      double totalInterestEarned = 0.0;

      // Fetch confirmed seed money payments
      QuerySnapshot seedMoneyPaymentsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('paymentType', isEqualTo: 'Seed Money')
          .where('status', isEqualTo: 'confirmed')
          .get();

      for (var doc in seedMoneyPaymentsSnapshot.docs) {
        totalSeedMoneyCollected += (doc['amount'] as num).toDouble();
      }

      // Fetch group's financial data
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupSnapshot.exists) {
        var data = groupSnapshot.data() as Map<String, dynamic>;

        // Fetch loans repayments and interest rate
        fixedInterestRate = (data['interestRate'] ?? 0.0).toDouble();

        // Calculate total interest as loan repayments + fixed interest rate, only for confirmed loans
        QuerySnapshot loanRepaymentsSnapshot = await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('loans')
            .where('status', isEqualTo: 'approved')  // Only confirmed/approved loans
            .get();

        for (var loanDoc in loanRepaymentsSnapshot.docs) {
          double monthlyRepayment = (loanDoc['monthlyRepayment'] ?? 0.0).toDouble();
          totalLoanRepayments += monthlyRepayment;
        }

        totalInterestEarned = totalLoanRepayments + fixedInterestRate;

        setState(() {
          totalSeedMoney = totalSeedMoneyCollected;
          totalInterest = totalInterestEarned;
          loanRepayments = totalLoanRepayments;
          quarterlyPayments = (data['quarterlyPayments'] ?? 0.0).toDouble();
          penaltiesPaid = (data['penaltiesPaid'] ?? 0.0).toDouble();
          approvedLoansForMonth = (data['approvedLoansForMonth'] ?? 0.0).toDouble();
          remainingLoanBalance = (data['remainingLoanBalance'] ?? 0.0).toDouble();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch group financial data: $e')),
      );
    }
  }

  Future<void> _fetchMembersContributions() async {
    try {
      QuerySnapshot membersSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('members')
          .get();

      setState(() {
        membersContributions = membersSnapshot.docs.map((doc) {
          return {
            'userId': doc['userId'],
            'name': doc['name'] ?? 'Unnamed',
            'totalContribution': doc['totalContribution'] ?? 0.0,
            'seedMoneyPaid': doc['seedMoneyPaid'] ?? 0.0,
            'loanRepayments': doc['loanRepayments'] ?? 0.0,
            'quarterlyPayments': doc['quarterlyPayments'] ?? 0.0,
            'penaltiesPaid': doc['penaltiesPaid'] ?? 0.0,
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch members contributions data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Total Contributions Details'),
        backgroundColor: Colors.teal,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchGroupFinancialData();
          await _fetchMembersContributions();
        },
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildOverviewTile(
              title: 'Total Seed Money Collected',
              value: totalSeedMoney,
              color: Colors.purpleAccent,
            ),
            SizedBox(height: 16),
            _buildOverviewTile(
              title: 'Total Interest Earned (Confirmed Loans)',
              value: totalInterest,
              color: Colors.blueAccent,
            ),
            SizedBox(height: 16),
            _buildOverviewTile(
              title: 'Total Loan Repayments',
              value: loanRepayments,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            _buildOverviewTile(
              title: 'Total Quarterly Payments',
              value: quarterlyPayments,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            _buildOverviewTile(
              title: 'Total Penalties Paid',
              value: penaltiesPaid,
              color: Colors.redAccent,
            ),
            SizedBox(height: 16),
            _buildOverviewTile(
              title: 'Approved Loans for This Month',
              value: approvedLoansForMonth,
              color: Colors.teal,
            ),
            SizedBox(height: 16),
            _buildOverviewTile(
              title: 'Remaining Loan Balance',
              value: remainingLoanBalance,
              color: Colors.indigo,
            ),
            SizedBox(height: 32),
            Text(
              'Members Contributions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            _buildMembersContributionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTile({required String title, required double value, required Color color}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'MWK ${value.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 18, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersContributionList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: membersContributions.length,
      itemBuilder: (context, index) {
        final member = membersContributions[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Text(
                member['name'].substring(0, 1).toUpperCase(),
                style: TextStyle(color: Colors.black),
              ),
            ),
            title: Text(member['name']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Contribution: MWK ${member['totalContribution'].toStringAsFixed(2)}'),
                Text('Seed Money Paid: MWK ${member['seedMoneyPaid'].toStringAsFixed(2)}'),
                Text('Loan Repayments: MWK ${member['loanRepayments'].toStringAsFixed(2)}'),
                Text('Quarterly Payments: MWK ${member['quarterlyPayments'].toStringAsFixed(2)}'),
                Text('Penalties Paid: MWK ${member['penaltiesPaid'].toStringAsFixed(2)}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
