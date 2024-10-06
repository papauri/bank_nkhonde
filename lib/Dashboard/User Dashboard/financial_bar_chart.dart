import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // For charts

class FinancialBarChart extends StatelessWidget {
  final double totalContribution;
  final double outstandingLoans;
  final double availableFunds;

  FinancialBarChart({
    required this.totalContribution,
    required this.outstandingLoans,
    required this.availableFunds,
  });

  @override
  Widget build(BuildContext context) {
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
                  if (!event.isInterestedForInteractions || barTouchResponse == null || barTouchResponse.spot == null) {
                    return;
                  }

                  final tappedGroupIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                  // Handle tap events on each bar (optional)
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
}
