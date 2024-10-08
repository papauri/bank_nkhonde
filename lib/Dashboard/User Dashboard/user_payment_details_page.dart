import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaymentDetailsPage extends StatefulWidget {
  final String groupId;
  final String userId;

  PaymentDetailsPage({required this.groupId, required this.userId});

  @override
  _PaymentDetailsPageState createState() => _PaymentDetailsPageState();
}

class _PaymentDetailsPageState extends State<PaymentDetailsPage> {
  late Future<Map<String, List<Map<String, dynamic>>>> _userPayments;

  @override
  void initState() {
    super.initState();
    _userPayments = _fetchPaymentsByMonthAndUser();
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchPaymentsByMonthAndUser() async {
    QuerySnapshot paymentSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('payments')
        .where('userId', isEqualTo: widget.userId)
        .where('paymentType', isEqualTo: 'Monthly Contribution')
        .orderBy('paymentDate', descending: true)
        .get();

    Map<String, List<Map<String, dynamic>>> groupedPayments = {};

    for (var doc in paymentSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;

      if (data != null && data.containsKey('paymentDate')) {
        DateTime paymentDate = (data['paymentDate'] as Timestamp).toDate();
        String monthYear = DateFormat('MMMM yyyy').format(paymentDate);

        if (!groupedPayments.containsKey(monthYear)) {
          groupedPayments[monthYear] = [];
        }

        groupedPayments[monthYear]!.add({
          'amount': data['amount'],
          'status': data['status'],
          'paymentDate': paymentDate,
          'transactionReference': data['transactionReference'],
          'screenshotUrl': data['screenshotUrl'],
        });
      }
    }

    return groupedPayments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment Details')),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _userPayments,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final paymentsByMonth = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildMonthlyPaymentsOverview(paymentsByMonth),
              SizedBox(height: 16),
              _buildUserPaymentsTable(paymentsByMonth),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthlyPaymentsOverview(Map<String, List<Map<String, dynamic>>> paymentsByMonth) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: paymentsByMonth.keys.length,
      itemBuilder: (context, monthIndex) {
        String monthYear = paymentsByMonth.keys.elementAt(monthIndex);
        List<Map<String, dynamic>> userPayments = paymentsByMonth[monthYear]!;

        return ExpansionTile(
          title: Text(
            'Payments for $monthYear',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          children: userPayments.map((payment) {
            String paymentDateFormatted = DateFormat('dd MMM yyyy').format(payment['paymentDate']);
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: payment['status'] == 'confirmed' ? Colors.green : Colors.orange,
                child: Icon(
                  payment['status'] == 'confirmed' ? Icons.check : Icons.hourglass_empty,
                  color: Colors.white,
                ),
              ),
              title: Text('MWK ${payment['amount'].toStringAsFixed(2)}'),
              subtitle: Text('Date: $paymentDateFormatted\nStatus: ${payment['status']}'),
              trailing: payment['screenshotUrl'] != null
                  ? IconButton(
                      icon: Icon(Icons.image, color: Colors.blue),
                      onPressed: () {
                        _showScreenshotDialog(context, payment['screenshotUrl']);
                      },
                    )
                  : null,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildUserPaymentsTable(Map<String, List<Map<String, dynamic>>> paymentsByMonth) {
    List<Map<String, dynamic>> allPayments = [];
    paymentsByMonth.forEach((_, payments) => allPayments.addAll(payments));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment History Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: Colors.grey, width: 1),
          columnWidths: {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[300]),
              children: [
                _buildTableCell('Date', isHeader: true),
                _buildTableCell('Amount', isHeader: true),
                _buildTableCell('Status', isHeader: true),
              ],
            ),
            ...allPayments.map((payment) {
              String paymentDateFormatted = DateFormat('dd MMM yyyy').format(payment['paymentDate']);
              return TableRow(
                children: [
                  _buildTableCell(paymentDateFormatted),
                  _buildTableCell('MWK ${payment['amount'].toStringAsFixed(2)}'),
                  _buildTableCell(payment['status']),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showScreenshotDialog(BuildContext context, String screenshotUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Payment Screenshot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 16),
                Image.network(screenshotUrl),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
