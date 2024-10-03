import 'package:flutter/material.dart';

class GroupHeader extends StatelessWidget {
  final double totalFunds;

  const GroupHeader({required this.totalFunds});

  @override
  Widget build(BuildContext context) {
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
}
