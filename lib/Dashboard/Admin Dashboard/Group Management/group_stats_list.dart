import 'package:flutter/material.dart';

class GroupStatsList extends StatelessWidget {
  final double totalContributions;
  final double pendingLoanAmount;
  final int pendingLoanApplicants;
  final int pendingPaymentsCount;
  final double seedMoney;
  final double interestRate;
  final double fixedAmount;
  final Function onStatTapped;

  const GroupStatsList({
    required this.totalContributions,
    required this.pendingLoanAmount,
    required this.pendingLoanApplicants,
    required this.pendingPaymentsCount,
    required this.seedMoney,
    required this.interestRate,
    required this.fixedAmount,
    required this.onStatTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatItem(
            context,
            title: 'Total Contributions',
            value: 'MWK ${totalContributions.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            onTap: () => onStatTapped('contributions'),
          ),
          _buildStatItem(
            context,
            title: 'Pending Loans',
            value: 'MWK ${pendingLoanAmount.toStringAsFixed(2)}',
            subtitle: 'Applicants: $pendingLoanApplicants',
            icon: Icons.hourglass_empty,
            onTap: () => onStatTapped('loans'),
          ),
          _buildStatItem(
            context,
            title: 'Pending Payments',
            value: 'MWK $pendingPaymentsCount Payments Pending',
            icon: Icons.payment,
            onTap: () => onStatTapped('pending_payments'), // Handle pending payments stat tap
          ),
          _buildStatItem(
            context,
            title: 'Seed Money',
            value: 'MWK ${seedMoney.toStringAsFixed(2)}',
            icon: Icons.money,
          ),
          _buildStatItem(
            context,
            title: 'Interest Rate',
            value: '${interestRate.toStringAsFixed(2)}%',
            icon: Icons.percent,
          ),
          _buildStatItem(
            context,
            title: 'Monthly Contribution',
            value: 'MWK ${fixedAmount.toStringAsFixed(2)}',
            icon: Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
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
}
