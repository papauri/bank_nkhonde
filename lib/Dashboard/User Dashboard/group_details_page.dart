import 'package:flutter/material.dart';
import 'apply_for_loan_page.dart';

class GroupDetailsPage extends StatelessWidget {
  final String groupId;
  final String groupName;

  GroupDetailsPage({required this.groupId, required this.groupName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(groupName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Group Details for $groupName', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApplyForLoanPage(groupId: groupId),
                  ),
                );
              },
              child: Text('Apply for Loan'),
            ),
          ],
        ),
      ),
    );
  }
}
