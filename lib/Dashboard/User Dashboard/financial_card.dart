import 'package:flutter/material.dart';

class FinancialCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const FinancialCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          padding: EdgeInsets.all(16),
          height: 140,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 32, color: color),
              Text(
                title,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              Text(
                'MWK ${amount.toStringAsFixed(2)}', // Change $ to MWK or another currency symbol
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
