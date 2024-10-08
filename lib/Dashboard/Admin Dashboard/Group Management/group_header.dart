import 'package:flutter/material.dart';
import 'yearly_payment_breakdown_page.dart'; // Import the yearly breakdown page
import 'payment_breakdown_page.dart'; // Monthly Breakdown Page
import 'seed_money_summary_page.dart'; // Seed Money Summary Page

class GroupHeader extends StatelessWidget {
  final double totalMonthlyContributions;
  final String groupId;

  const GroupHeader({required this.totalMonthlyContributions, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Monthly Contributions Tile
            Expanded(
              child: _buildColoredTile(
                context,
                title: 'Monthly Contributions',
                subtitle: 'MWK ${totalMonthlyContributions.toStringAsFixed(2)}',
                colors: [Colors.blueAccent, Colors.lightBlueAccent],
                icon: Icons.monetization_on,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentBreakdownPage(groupId: groupId),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 10),
            // Yearly Contributions Tile
            Expanded(
              child: _buildColoredTile(
                context,
                title: 'Yearly Contributions',
                subtitle: 'Tap to View Yearly Breakdown',
                colors: [Colors.green, Colors.lightGreen],
                icon: Icons.calendar_today,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => YearlyPaymentBreakdownPage(groupId: groupId),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        // Seed Money Summary Tile
        _buildColoredTile(
          context,
          title: 'Seed Money Summary',
          subtitle: 'Tap to View Members\' Payments',
          colors: [Colors.deepPurple, Colors.purpleAccent],
          icon: Icons.group,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SeedMoneySummaryPage(groupId: groupId),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildColoredTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Color> colors,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        margin: EdgeInsets.symmetric(horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
