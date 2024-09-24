import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              // Implement loan application functionality
            },
            icon: Icon(Icons.request_page),
            label: Text('Request Loan'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Implement contribution history functionality
            },
            icon: Icon(Icons.history),
            label: Text('Contribution History'),
          ),
        ],
      ),
    );
  }
}
