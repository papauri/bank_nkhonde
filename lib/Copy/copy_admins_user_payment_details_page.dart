import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';  // For date formatting

class PaymentDetailsPage extends StatelessWidget {
  final String groupId;
  final String userId;

  PaymentDetailsPage({required this.groupId, required this.userId});

  Future<Map<String, Map<String, List<Map<String, dynamic>>>>> _fetchPaymentsByMonthAndUser() async {
    QuerySnapshot paymentSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('payments')
        .orderBy('paymentDate', descending: true)
        .get();

    // Group payments first by 'MMMM yyyy', then by user
    Map<String, Map<String, List<Map<String, dynamic>>>> groupedPayments = {};

    for (var doc in paymentSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;

      if (data != null && data.containsKey('paymentDate')) {
        DateTime paymentDate = (data['paymentDate'] as Timestamp).toDate();
        String monthYear = DateFormat('MMMM yyyy').format(paymentDate); // Group by month/year
        String payerName = data['payerName'] ?? 'Unnamed';

        // Ensure month/year group exists
        if (!groupedPayments.containsKey(monthYear)) {
          groupedPayments[monthYear] = {};
        }

        // Ensure payer group exists under the month/year
        if (!groupedPayments[monthYear]!.containsKey(payerName)) {
          groupedPayments[monthYear]![payerName] = [];
        }

        groupedPayments[monthYear]![payerName]!.add({
          'payerName': payerName,
          'amount': data['amount'],
          'status': data['status'],
          'paymentDate': paymentDate,
        });
      }
    }

    return groupedPayments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Details'),
      ),
      body: FutureBuilder<Map<String, Map<String, List<Map<String, dynamic>>>>>(
        future: _fetchPaymentsByMonthAndUser(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final paymentsByMonthAndUser = snapshot.data!;

          if (paymentsByMonthAndUser.isEmpty) {
            return Center(child: Text('No payments found.'));
          }

          return ListView.builder(
            itemCount: paymentsByMonthAndUser.keys.length,
            itemBuilder: (context, monthIndex) {
              String monthYear = paymentsByMonthAndUser.keys.elementAt(monthIndex);
              Map<String, List<Map<String, dynamic>>> paymentsByUser = paymentsByMonthAndUser[monthYear]!;

              return ExpansionTile(
                title: Text(
                  'Payments for $monthYear',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Click to expand and see the payments made during this month.'),
                children: paymentsByUser.keys.map((payerName) {
                  List<Map<String, dynamic>> userPayments = paymentsByUser[payerName]!;

                  return ExpansionTile(
                    title: Text(
                      payerName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${userPayments.length} payment(s)'),
                    children: userPayments.map((payment) {
                      String paymentDateFormatted = DateFormat('dd MMM yyyy').format(payment['paymentDate']);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: payment['status'] == 'confirmed'
                              ? Colors.green
                              : Colors.orange,
                          child: Icon(
                            payment['status'] == 'confirmed'
                                ? Icons.check
                                : Icons.hourglass_empty,
                            color: Colors.white,
                          ),
                        ),
                        title: Text('Paid MWK ${payment['amount']}'),
                        subtitle: Text(
                          'Status: ${payment['status']}, Date: $paymentDateFormatted',
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
