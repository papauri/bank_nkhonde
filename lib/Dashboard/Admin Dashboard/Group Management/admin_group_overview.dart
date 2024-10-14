import 'package:bank_nkhonde/Account%20Management/member_management_page.dart';
import 'package:bank_nkhonde/Dashboard/Admin%20Dashboard/Group%20Management/edit_group_parameters.dart';
import 'package:bank_nkhonde/Login%20Page/login_page.dart';
import 'package:bank_nkhonde/Payment%20Management/loan_management_page.dart';
import 'package:bank_nkhonde/Payment%20Management/payment_management_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'group_header.dart';
import 'group_stats_list.dart';

class GroupOverviewPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  GroupOverviewPage({required this.groupId, required this.groupName});

  @override
  _GroupOverviewPageState createState() => _GroupOverviewPageState();
}

class _GroupOverviewPageState extends State<GroupOverviewPage> {
  double totalContributions = 0.0;
  double totalYearlyContributions = 0.0;
  double currentMonthContributions = 0.0;
  double pendingLoanAmount = 0.0;
  int pendingLoanApplicants = 0;
  double seedMoney = 0.0;
  double interestRate = 0.0;
  double fixedAmount = 0.0;
  double quarterlyPaymentAmount = 0.0;
  int pendingPaymentsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
  }

  Future<void> _fetchGroupData() async {
    await Future.wait([
      _fetchBasicGroupDetails(),
      _fetchPendingLoans(),
      _fetchContributions(),
      _fetchPendingPayments(),
      _fetchCurrentMonthContributions(),
    ]);
  }

  Future<void> _fetchBasicGroupDetails() async {
    try {
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupSnapshot.exists) {
        final data = groupSnapshot.data() as Map<String, dynamic>;
        setState(() {
          seedMoney = data['seedMoney']?.toDouble() ?? 0.0;
          interestRate = data['interestRate']?.toDouble() ?? 0.0;
          fixedAmount = data['fixedAmount']?.toDouble() ?? 0.0;
          quarterlyPaymentAmount =
              data['quarterlyPaymentAmount']?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      _showError('Failed to fetch group data.');
    }
  }

  Future<void> _fetchPendingLoans() async {
    try {
      QuerySnapshot loanSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('loans')
          .where('status', isEqualTo: 'pending')
          .get();

      double totalPendingAmount = loanSnapshot.docs
          .fold(0.0, (sum, loan) => sum + (loan['amount']?.toDouble() ?? 0.0));

      setState(() {
        pendingLoanAmount = totalPendingAmount;
        pendingLoanApplicants = loanSnapshot.docs.length;
      });
    } catch (e) {
      _showError('Failed to fetch pending loans.');
    }
  }

  Future<void> _fetchContributions() async {
    try {
      double contributionsSum = 0.0,
          loanPaymentsSum = 0.0,
          penaltiesSum = 0.0,
          interestSum = 0.0;

      QuerySnapshot monthlyPaymentsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('status', isEqualTo: 'confirmed')
          .get();

      for (var payment in monthlyPaymentsSnapshot.docs) {
        double amount = payment['amount']?.toDouble() ?? 0.0;
        switch (payment['paymentType']) {
          case 'Monthly Contribution':
            contributionsSum += amount;
            break;
          case 'Loan Payment':
            loanPaymentsSum += amount;
            break;
          case 'Penalty':
            penaltiesSum += amount;
            break;
          case 'Interest':
            interestSum += amount;
            break;
        }
      }

      setState(() {
        totalContributions = contributionsSum;
        totalYearlyContributions =
            contributionsSum + loanPaymentsSum + penaltiesSum + interestSum;
      });
    } catch (e) {
      _showError('Failed to fetch total contributions.');
    }
  }

  Future<void> _fetchPendingPayments() async {
    try {
      QuerySnapshot paymentsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('status', isEqualTo: 'pending')
          .get();

      setState(() {
        pendingPaymentsCount = paymentsSnapshot.docs.length;
      });
    } catch (e) {
      _showError('Failed to fetch pending payments.');
    }
  }

  Future<void> _fetchCurrentMonthContributions() async {
    try {
      DateTime now = DateTime.now();
      String currentMonth = DateFormat('MMMM yyyy').format(now);

      QuerySnapshot currentMonthPaymentsSnapshot = await FirebaseFirestore
          .instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('status', isEqualTo: 'confirmed')
          .where('paymentType', isEqualTo: 'Monthly Contribution')
          .get();

      double currentMonthSum =
          currentMonthPaymentsSnapshot.docs.fold(0.0, (sum, payment) {
        DateTime paymentDate = (payment['paymentDate'] as Timestamp).toDate();
        String paymentMonth = DateFormat('MMMM yyyy').format(paymentDate);
        return paymentMonth == currentMonth
            ? sum + (payment['amount']?.toDouble() ?? 0.0)
            : sum;
      });

      setState(() {
        currentMonthContributions = currentMonthSum;
      });
    } catch (e) {
      _showError('Failed to fetch current month contributions.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
        onRefresh: _fetchGroupData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              GroupHeader(
                currentMonthContributions: currentMonthContributions,
                totalYearlyContributions: totalYearlyContributions,
                totalContributions: totalContributions,
                quarterlyPaymentAmount: quarterlyPaymentAmount,
                groupId: widget.groupId,
                groupName: widget.groupName,
              ),
              GroupStatsList(
                pendingLoanApplicants: pendingLoanApplicants,
                pendingPaymentsCount: pendingPaymentsCount,
                seedMoney: seedMoney,
                interestRate: interestRate,
                fixedAmount: fixedAmount,
                onStatTapped: _handleStatTap,
                onViewMembers: () => _navigateToPage(MemberManagementPage(
                  groupId: widget.groupId,
                  groupName: widget.groupName,
                )),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on),
            label: 'Loans',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0: // Case for logout
              _handleLogout(context);
              break;
            case 1: // Case for loans
              _navigateToPage(LoanManagementPage(
                groupId: widget.groupId,
                groupName: widget.groupName,
              ));
              break;
            case 2: // Case for payments
              _navigateToPage(PaymentManagementPage(
                groupId: widget.groupId,
                groupName: widget.groupName,
              ));
              break;
            case 3: // Case for settings
              _showEditGroupParametersDialog();
              break;
          }
        },
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
      ),
    );
  }

  void _handleStatTap(String statType) {
    if (statType == 'loans') {
      _navigateToPage(LoanManagementPage(
        groupId: widget.groupId,
        groupName: widget.groupName,
      ));
    } else if (statType == 'pending_payments') {
      _navigateToPage(PaymentManagementPage(
        groupId: widget.groupId,
        groupName: widget.groupName,
      ));
    }
  }

  void _navigateToPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
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

  void _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut(); // Sign out the user from Firebase

      // Navigate to the login page and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );

      // Optionally, show a logout success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged out successfully')),
      );
    } catch (e) {
      // Handle any errors that might occur during logout
      print('Logout Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out. Please try again.')),
      );
    }
  }
}
