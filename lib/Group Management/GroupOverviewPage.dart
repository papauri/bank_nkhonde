import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Payment Management/PendingLoansPage.dart';
import '../Payment Management/contributions_overview_page.dart';
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
  double fixedAmount = 0.0;
  double interestRate = 0.0;
  double seedMoney = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
    _fetchTotalContributions();
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
          .where('status', isEqualTo: 'confirmed')
          .get();

      double contributionsSum = 0.0;

      for (var payment in paymentsSnapshot.docs) {
        contributionsSum += payment['amount']?.toDouble() ?? 0.0;
      }

      setState(() {
        totalContributions = contributionsSum;
        totalFunds = seedMoney + totalContributions - pendingLoanAmount;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch total contributions.')),
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
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeaderSection(),
              _buildStatsList(),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        children: [
          Text(
            'Total Funds Available',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          SizedBox(height: 10),
          Text(
            'MWK ${totalFunds.toStringAsFixed(2)}',
            style: TextStyle(
                color: Colors.black, fontSize: 36, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsList() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatItem(
            title: 'Total Contributions',
            value: 'MWK ${totalContributions.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ContributionsOverviewPage(groupId: widget.groupId),
                ),
              );
            },
          ),
          _buildStatItem(
            title: 'Pending Loans',
            value: 'MWK ${pendingLoanAmount.toStringAsFixed(2)}',
            subtitle: 'Applicants: $pendingLoanApplicants',
            icon: Icons.hourglass_empty,
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
          _buildStatItem(
            title: 'Seed Money',
            value: 'MWK ${seedMoney.toStringAsFixed(2)}',
            icon: Icons.money,
          ),
          _buildStatItem(
            title: 'Interest Rate',
            value: '${interestRate.toStringAsFixed(2)}%',
            icon: Icons.percent,
          ),
          _buildStatItem(
            title: 'Monthly Contribution',
            value: 'MWK ${fixedAmount.toStringAsFixed(2)}',
            icon: Icons.calendar_today,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showEditParametersDialog,
            child: Text('Edit Group Parameters'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    Function()? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Text(
        value,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildActionButton(
            label: 'View Members',
            icon: Icons.group,
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
          ),
          _buildActionButton(
            label: 'Manage Loans',
            icon: Icons.monetization_on,
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
          ),
          _buildActionButton(
            label: 'Manage Payments',
            icon: Icons.payment,
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
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Function() onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 6),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.black),
        label: Text(label, style: TextStyle(color: Colors.black)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.black),
          padding: EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  void _showEditParametersDialog() {
    final TextEditingController _fixedAmountController =
        TextEditingController(text: fixedAmount.toString());
    final TextEditingController _interestRateController =
        TextEditingController(text: interestRate.toString());
    final TextEditingController _seedMoneyController =
        TextEditingController(text: seedMoney.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Group Parameters'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildParameterTextField(
                  controller: _seedMoneyController,
                  label: 'Seed Money (MWK)',
                ),
                _buildParameterTextField(
                  controller: _interestRateController,
                  label: 'Interest Rate (%)',
                ),
                _buildParameterTextField(
                  controller: _fixedAmountController,
                  label: 'Monthly Contribution (MWK)',
                ),
                SizedBox(height: 10),
                Text(
                  'Changing these parameters will affect existing loans and contributions. Proceed with caution.',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () {
                _updateGroupParameters(
                  _seedMoneyController.text,
                  _interestRateController.text,
                  _fixedAmountController.text,
                );
                Navigator.pop(context);
              },
              child: Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildParameterTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }

  void _updateGroupParameters(
    String newSeedMoney,
    String newInterestRate,
    String newFixedAmount,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
        'seedMoney': double.parse(newSeedMoney),
        'interestRate': double.parse(newInterestRate),
        'fixedAmount': double.parse(newFixedAmount),
      });

      setState(() {
        seedMoney = double.parse(newSeedMoney);
        interestRate = double.parse(newInterestRate);
        fixedAmount = double.parse(newFixedAmount);
        totalFunds = seedMoney + totalContributions - pendingLoanAmount;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group parameters updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to update group parameters. Try again.')),
      );
    }
  }
}
