import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart'; // For charts
import 'financial_card.dart';
import 'member_list_tile.dart';
import 'payment_details_page.dart'; // Import the new payment details page

class GroupDetailsPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  GroupDetailsPage({required this.groupId, required this.groupName});

  @override
  _GroupDetailsPageState createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  double totalContribution = 0.0;
  double outstandingLoans = 0.0;
  double availableFunds = 0.0;
  List<Map<String, dynamic>> members = [];

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
    _fetchTotalConfirmedContributions();
  }

  Future<void> _fetchGroupData() async {
    try {
      DocumentSnapshot groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupDoc.exists) {
        var data = groupDoc.data() as Map<String, dynamic>;
        setState(() {
          outstandingLoans = (data['outstandingLoans'] ?? 0).toDouble();
          availableFunds = (data['availableFunds'] ?? 0).toDouble();
          members = List<Map<String, dynamic>>.from(data['members'] ?? []);
        });
      }
    } catch (e) {
      print('Error fetching group data: $e');
    }
  }

  Future<void> _fetchTotalConfirmedContributions() async {
    try {
      QuerySnapshot paymentSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('status', whereIn: ['confirmed', 'pending'])  // Fetch both confirmed and pending
          .get();

      double totalContributions = 0.0;
      for (var doc in paymentSnapshot.docs) {
        totalContributions += (doc['amount'] as num).toDouble();
      }

      setState(() {
        totalContribution = totalContributions;
      });
    } catch (e) {
      print('Error fetching confirmed contributions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.blueGrey[800]!;
    final Color accentColor = Colors.blueGrey[50]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        children: [
          // Financial Overview Section
          Text(
            'Financial Overview',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildFinancialOverview(),

          SizedBox(height: 32),

          // Bar Chart Section
          _buildFinancialBarChart(),  // Updated with correct interactivity

          SizedBox(height: 32),

          // Apply for Loan Button
          _buildApplyForLoanButton(primaryColor),

          SizedBox(height: 32),

          // Members Section
          Text(
            'Group Members',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildMembersList(),
        ],
      ),
    );
  }

  Widget _buildFinancialOverview() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FinancialCard(
          title: 'Contributions',
          amount: totalContribution,
          icon: Icons.attach_money,
          color: Colors.green,
        ),
        FinancialCard(
          title: 'Loans',
          amount: outstandingLoans,
          icon: Icons.money_off,
          color: Colors.redAccent,
        ),
        FinancialCard(
          title: 'Available',
          amount: availableFunds,
          icon: Icons.account_balance_wallet,
          color: Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildFinancialBarChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Funds Distribution',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1.5,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.grey,
                ),
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  if (!event.isInterestedForInteractions ||
                      barTouchResponse == null ||
                      barTouchResponse.spot == null) {
                    return;
                  }

                  final tappedGroupIndex = barTouchResponse.spot!.touchedBarGroupIndex;

                  if (tappedGroupIndex == 0) {
                    // Navigate to PaymentDetailsPage if contributions bar is tapped
                    _navigateToPaymentDetails(context);
                  }
                },
              ),
              barGroups: [
                _buildBarGroup(0, totalContribution, Colors.green, 'Contributions'),
                _buildBarGroup(1, outstandingLoans, Colors.redAccent, 'Loans'),
                _buildBarGroup(2, availableFunds, Colors.blueAccent, 'Available'),
              ],
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: SideTitles(
                  showTitles: true,
                  getTitles: (double value) {
                    switch (value.toInt()) {
                      case 0:
                        return 'Contributions';
                      case 1:
                        return 'Loans';
                      case 2:
                        return 'Available';
                      default:
                        return '';
                    }
                  },
                ),
                leftTitles: SideTitles(showTitles: true),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color, String title) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          y: y,
          colors: [color],
          width: 22,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  void _navigateToPaymentDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentDetailsPage(groupId: widget.groupId),  // Navigate to payment details
      ),
    );
  }

  Widget _buildApplyForLoanButton(Color primaryColor) {
    return ElevatedButton(
      onPressed: () {
        // Navigate to loan application page or show a dialog
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        'Apply for Loan',
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }

  Widget _buildMembersList() {
    if (members.isEmpty) {
      return Center(child: Text('No members found.'));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: members.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        final member = members[index];
        return MemberListTile(
          name: member['name'] ?? 'Unnamed',
          profilePictureUrl: member['profilePicture'],
          memberId: member['userId'],
        );
      },
    );
  }
}
