import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // To format dates

class PastPaymentsPage extends StatefulWidget {
  final String groupId;
  final String userId; // The ID of the logged-in user

  PastPaymentsPage({required this.groupId, required this.userId});

  @override
  _PastPaymentsPageState createState() => _PastPaymentsPageState();
}

class _PastPaymentsPageState extends State<PastPaymentsPage> {
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Past Payments'),
        backgroundColor: Colors.teal[800],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: pastMonths.map((month) {
          return _buildMonthSection(month);
        }).toList(),
      ),
    );
  }

  Widget _buildMonthSection(String month) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('userId', isEqualTo: widget.userId) // Only the logged-in user's payments
          .where('paymentMonth', isEqualTo: month) // Payments for the selected month
          .where('status', isEqualTo: 'confirmed') // Only confirmed payments
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final payments = snapshot.data!.docs;
        if (payments.isEmpty) {
          return ExpansionTile(
            title: Text(
              month,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            children: [ListTile(title: Text('No payments found for $month'))],
          );
        }

        double totalForMonth = payments.fold(
          0.0,
          (sum, payment) => sum + (payment['amount'] as num).toDouble(),
        );

        return ExpansionTile(
          title: Text(
            '$month - Total: MWK ${totalForMonth.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          children: payments.map((payment) {
            return ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('MWK ${payment['amount']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${_formatDate(payment['paymentDate'])}'),
                  if (payment['transactionReference'] != null)
                    Text('Reference: ${payment['transactionReference']}'),
                ],
              ),
              trailing: payment['screenshotUrl'] != null
                  ? GestureDetector(
                      onTap: () {
                        _showImageDialog(context, payment['screenshotUrl']);
                      },
                      child: Icon(Icons.image, color: Colors.blue),
                    )
                  : null,
            );
          }).toList(),
        );
      },
    );
  }

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('EEEE, MMM d, yyyy').format(date);
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Image.network(imageUrl),
          ),
        );
      },
    );
  }
}
