import 'package:bank_nkhonde/Dashboard/User%20Dashboard/user_payment_page.dart';
import 'package:flutter/material.dart';

class FinancialOverview extends StatelessWidget {
  final double totalContribution;
  final double outstandingLoans;
  final double availableFunds;
  final String groupId;  // Add the groupId parameter

  FinancialOverview({
    required this.totalContribution,
    required this.outstandingLoans,
    required this.availableFunds,
    required this.groupId,  // Initialize groupId
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Financial Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text('Total Contribution: MWK $totalContribution'),
          LinearProgressIndicator(
            value: totalContribution / 10000, // Assuming max contribution is 10,000 MWK
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          SizedBox(height: 20),
          Text('Outstanding Loans: MWK $outstandingLoans'),
          LinearProgressIndicator(
            value: outstandingLoans / 5000, // Example for loans max at 5000 MWK
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
          ),
          SizedBox(height: 20),
          Text('Available Funds: MWK $availableFunds'),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentPage(groupId: groupId),  // Pass groupId to PaymentPage
                ),
              );
            },
            child: Text('Make a Payment'),
          ),
        ],
      ),
    );
  }
}
