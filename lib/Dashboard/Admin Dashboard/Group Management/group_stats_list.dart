import 'package:flutter/material.dart';

class GroupStatsList extends StatelessWidget {
  final int pendingLoanApplicants;
  final int pendingPaymentsCount;
  final double seedMoney;
  final double interestRate;
  final double fixedAmount;
  final Function onStatTapped;
  final Function onViewMembers;

  const GroupStatsList({
    required this.pendingLoanApplicants,
    required this.pendingPaymentsCount,
    required this.seedMoney,
    required this.interestRate,
    required this.fixedAmount,
    required this.onStatTapped,
    required this.onViewMembers, required int pendingLoanRepayments, required double pendingRepaymentAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Row for clickable stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildClickableTile(
                context,
                title: 'View Members',
                value: 'Manage Members',
                icon: Icons.group,
                onTap: () => onViewMembers(),
              ),
              _buildClickableTile(
                context,
                title: 'Loans',
                value: '$pendingLoanApplicants Pending', // Display pending applicants
                icon: Icons.hourglass_empty,
                onTap: () => onStatTapped('loans'),
              ),
              _buildClickableTile(
                context,
                title: 'Payments',
                value: '$pendingPaymentsCount Pending', // Display pending payments count
                icon: Icons.payment,
                onTap: () => onStatTapped('pending_payments'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDropdownInfoSection(context),
        ],
      ),
    );
  }

  Widget _buildClickableTile(
    BuildContext context, {
    required String title,
    required String value,
    IconData? icon,
    Function()? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110, // Uniform width
        height: 110, // Uniform height
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, size: 30, color: Colors.teal),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownInfoSection(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'Group Details',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: Icon(Icons.info_outline, color: Colors.teal, size: 30),
      children: [
        ListTile(
          leading: Icon(Icons.money, color: Colors.black),
          title: Text('Seed Money'),
          trailing: Text(
            'MWK ${seedMoney.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: Icon(Icons.percent, color: Colors.black),
          title: Text('Interest Rate'),
          trailing: Text(
            '${interestRate.toStringAsFixed(2)}%',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: Icon(Icons.calendar_today, color: Colors.black),
          title: Text('Monthly Contribution'),
          trailing: Text(
            'MWK ${fixedAmount.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
