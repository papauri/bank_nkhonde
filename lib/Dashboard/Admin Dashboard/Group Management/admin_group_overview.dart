import 'package:bank_nkhonde/Account%20Management/member_management_page.dart';
import 'package:bank_nkhonde/Dashboard/Admin%20Dashboard/Group%20Management/edit_group_parameters.dart';
import 'package:bank_nkhonde/Dashboard/Admin%20Dashboard/Group%20Management/group_action_buttons.dart';
import 'package:bank_nkhonde/Payment%20Management/PendingLoansPage.dart';
import 'package:bank_nkhonde/Payment%20Management/contributions_overview_page.dart';
import 'package:bank_nkhonde/Payment%20Management/loan_management_page.dart';
import 'package:bank_nkhonde/Payment%20Management/payment_management_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'group_header.dart';
import 'group_stats_list.dart';
import 'payment_breakdown_page.dart';

class GroupOverviewPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  GroupOverviewPage({required this.groupId, required this.groupName});

  @override
  _GroupOverviewPageState createState() => _GroupOverviewPageState();
}

class _GroupOverviewPageState extends State<GroupOverviewPage> {
  double totalContributions = 0.0;
  double pendingLoanAmount = 0.0;
  int pendingLoanApplicants = 0;
  double seedMoney = 0.0;
  double interestRate = 0.0;
  double fixedAmount = 0.0;
  int pendingPaymentsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
    _fetchTotalContributions();
    _fetchPendingPayments();
  }

  Future<void> _fetchGroupData() async {
    try {
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupSnapshot.exists) {
        final data = groupSnapshot.data() as Map<String, dynamic>;

        setState(() {
          seedMoney = (data['seedMoney']?.toDouble() ?? 0.0);
          interestRate = (data['interestRate']?.toDouble() ?? 0.0);
          fixedAmount = (data['fixedAmount']?.toDouble() ?? 0.0);
        });
      }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch group data.')),
      );
    }
  }

  Future<void> _fetchTotalContributions() async {
    try {
      QuerySnapshot paymentsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('status', isEqualTo: 'confirmed') // Fetch only confirmed payments
          .where('paymentType', isEqualTo: 'Monthly Contribution')
          .get();

      double contributionsSum = 0.0;

      for (var payment in paymentsSnapshot.docs) {
        contributionsSum += payment['amount']?.toDouble() ?? 0.0; // Sum confirmed payments
      }

      setState(() {
        totalContributions = contributionsSum;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch total contributions.')),
      );
    }
  }

  Future<void> _fetchPendingPayments() async {
    try {
      QuerySnapshot paymentsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('status', isEqualTo: 'pending') // Fetch pending payments
          .where('paymentType', isEqualTo: 'Monthly Contribution')
          .get();

      int paymentsCount = paymentsSnapshot.docs.length;

      setState(() {
        pendingPaymentsCount = paymentsCount;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch pending payments.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchGroupData();
          await _fetchTotalContributions();
          await _fetchPendingPayments();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              GroupHeader(
                totalMonthlyContributions: totalContributions,
                groupId: widget.groupId,
              ),
              GroupStatsList(
                totalContributions: totalContributions,
                pendingLoanAmount: pendingLoanAmount,
                pendingLoanApplicants: pendingLoanApplicants,
                pendingPaymentsCount: pendingPaymentsCount,
                seedMoney: seedMoney,
                interestRate: interestRate,
                fixedAmount: fixedAmount,
                onStatTapped: _handleStatTap,
              ),
              GroupActionButtons(
                onViewMembers: _viewMembers,
                onManageLoans: _manageLoans,
                onManagePayments: _managePayments,
                onEditGroupSettings: _showEditGroupParametersDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleStatTap(String statType) {
    if (statType == 'contributions') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContributionsOverviewPage(groupId: widget.groupId),
        ),
      );
    } else if (statType == 'loans') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PendingLoansPage(
            groupId: widget.groupId,
            groupName: widget.groupName,
          ),
        ),
      );
    } else if (statType == 'pending_payments') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentManagementPage(
            groupId: widget.groupId,
            groupName: widget.groupName,
          ),
        ),
      );
    }
  }

  void _showEditGroupParametersDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return EditGroupParametersDialog(
          groupId: widget.groupId,
          seedMoney: seedMoney,
          interestRate: interestRate,
          fixedAmount: fixedAmount,
          onSave: (newSeedMoney, newInterestRate, newFixedAmount) {
            setState(() {
              seedMoney = newSeedMoney;
              interestRate = newInterestRate;
              fixedAmount = newFixedAmount;
            });
          },
        );
      },
    );
  }

  void _viewMembers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberManagementPage(
          groupId: widget.groupId,
          groupName: widget.groupName,
        ),
      ),
    );
  }

  void _manageLoans() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoanManagementPage(
          groupId: widget.groupId,
          groupName: widget.groupName,
        ),
      ),
    );
  }

  void _managePayments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentManagementPage(
          groupId: widget.groupId,
          groupName: widget.groupName,
        ),
      ),
    );
  }
}
