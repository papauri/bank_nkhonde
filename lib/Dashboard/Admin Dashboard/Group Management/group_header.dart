import 'package:bank_nkhonde/Payment%20Management/QuarterlyPaymentPage.dart';
import 'package:flutter/material.dart';
import 'yearly_payment_breakdown_page.dart'; // Import the yearly breakdown page
import 'payment_breakdown_page.dart'; // Monthly Breakdown Page
import 'seed_money_summary_page.dart'; // Seed Money Summary Page
import 'package:intl/intl.dart';

class GroupHeader extends StatelessWidget {
  final double currentMonthContributions;
  final double totalYearlyContributions;
  final double totalContributions;
  final double quarterlyPaymentAmount;
  final String groupId;
  final String groupName;

  const GroupHeader({
    required this.currentMonthContributions,
    required this.totalYearlyContributions,
    required this.totalContributions,
    required this.quarterlyPaymentAmount,
    required this.groupId,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    String currentMonth = DateFormat('MMMM').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              // Current Month Contributions Tile
              Expanded(
                child: _buildColoredTile(
                  context,
                  title: '$currentMonth Contributions',
                  subtitle:
                      'Tap to view - MWK ${currentMonthContributions.toStringAsFixed(2)}',
                  colors: [Colors.orangeAccent, Colors.deepOrangeAccent],
                  icon: Icons.monetization_on,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PaymentBreakdownPage(groupId: groupId),
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
                  subtitle:
                      'Tap to view - MWK ${totalYearlyContributions.toStringAsFixed(2)}',
                  colors: [Colors.lightGreen, Colors.green],
                  icon: Icons.calendar_today,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            YearlyPaymentBreakdownPage(groupId: groupId),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              // Quarterly Payments Tile
              Expanded(
                child: _buildColoredTile(
                  context,
                  title: 'Quarterly Payments',
                  subtitle: quarterlyPaymentAmount > 0
                      ? 'Tap to view quarterly payments'
                      : 'No quarterly payments set',
                  colors: [Colors.lightBlue, Colors.blueAccent],
                  icon: Icons.attach_money,
                  onTap: quarterlyPaymentAmount > 0
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuarterlyPaymentPage(
                                groupId: groupId,
                                groupName: groupName,
                              ),
                            ),
                          );
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'No quarterly payments set for this group.')),
                          );
                        },
                ),
              ),

              SizedBox(width: 10),
              // Seed Money Summary Tile
              Expanded(
                child: _buildColoredTile(
                  context,
                  title: 'Seed Money Summary',
                  subtitle: 'Tap to view members\' payments',
                  colors: [Colors.purpleAccent, Colors.deepPurple],
                  icon: Icons.group,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SeedMoneySummaryPage(groupId: groupId),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColoredTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Color> colors,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
            minHeight: 170,
            maxHeight: 170), // Ensuring consistent height for all tiles
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.4),
              spreadRadius: 3,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
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
