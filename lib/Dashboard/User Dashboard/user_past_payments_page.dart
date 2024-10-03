import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // To format dates

class PastPaymentsPage extends StatelessWidget {
  final String groupId;
  final Function(String) onMonthSelected;

  PastPaymentsPage({required this.groupId, required this.onMonthSelected});

  List<String> _getPastMonths() {
    List<String> months = [];
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('MMMM yyyy');

    for (int i = 1; i <= 12; i++) {
      DateTime pastMonth = DateTime(now.year, now.month - i, 1);
      months.add(formatter.format(pastMonth));
    }
    return months;
  }

  @override
  Widget build(BuildContext context) {
    List<String> pastMonths = _getPastMonths();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Select Month:'),
        DropdownButton<String>(
          hint: Text('Choose past month'),
          items: pastMonths.map((String month) {
            return DropdownMenuItem<String>(
              value: month,
              child: Text(month),
            );
          }).toList(),
          onChanged: (String? value) {
            if (value != null) {
              onMonthSelected(value);
            }
          },
        ),
      ],
    );
  }
}
