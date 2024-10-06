import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaymentBreakdownPage extends StatefulWidget {
  final String groupId;

  PaymentBreakdownPage({required this.groupId});

  @override
  _PaymentBreakdownPageState createState() => _PaymentBreakdownPageState();
}

class _PaymentBreakdownPageState extends State<PaymentBreakdownPage> {
  Future<void> _refreshPayments() async {
    setState(() {}); // Trigger a refresh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Breakdown'),
        backgroundColor: Colors.teal[800],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPayments,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .collection('payments')
              .where('status', isEqualTo: 'confirmed') // Only confirmed payments
              .orderBy('paymentDate', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final payments = snapshot.data!.docs;
            if (payments.isEmpty) {
              return Center(
                child: Text('No confirmed payments found.'),
              );
            }

            // Group payments by year, then by month, then by user
            Map<String, Map<String, Map<String, List<QueryDocumentSnapshot>>>> groupedPayments = {};

            for (var payment in payments) {
              final paymentDate = (payment['paymentDate'] as Timestamp).toDate();
              String year = DateFormat('yyyy').format(paymentDate);
              String month = DateFormat('MMMM').format(paymentDate);
              String payerName = payment['payerName'];

              groupedPayments[year] = groupedPayments[year] ?? {};
              groupedPayments[year]![month] = groupedPayments[year]![month] ?? {};
              groupedPayments[year]![month]![payerName] = groupedPayments[year]![month]![payerName] ?? [];
              groupedPayments[year]![month]![payerName]!.add(payment);
            }

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: groupedPayments.entries.map((yearEntry) {
                return _buildYearSection(yearEntry.key, yearEntry.value);
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildYearSection(String year, Map<String, Map<String, List<QueryDocumentSnapshot>>> paymentsByMonth) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          year,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: paymentsByMonth.entries.map((monthEntry) {
          return _buildMonthSection(monthEntry.key, monthEntry.value);
        }).toList(),
      ),
    );
  }

  Widget _buildMonthSection(String month, Map<String, List<QueryDocumentSnapshot>> paymentsByUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.teal[50],
          child: Text(
            month,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        ...paymentsByUser.entries.map((userEntry) {
          String payerName = userEntry.key;
          double totalForUser = userEntry.value.fold(
              0.0, (sum, payment) => sum + (payment['amount']?.toDouble() ?? 0.0));

          return _buildUserSection(payerName, totalForUser, userEntry.value);
        }).toList(),
      ],
    );
  }

  Widget _buildUserSection(String payerName, double totalForUser, List<QueryDocumentSnapshot> payments) {
    return ExpansionTile(
      title: Text(
        '$payerName - Total: MWK ${totalForUser.toStringAsFixed(2)}',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      children: payments.map((payment) {
        return ListTile(
          leading: Icon(
            Icons.check_circle,
            color: Colors.green,
          ),
          title: Text('MWK ${payment['amount']}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Payment Date: ${_formatDate(payment['paymentDate'])}'),
              if (payment['transactionReference'] != null)
                Text('Reference: ${payment['transactionReference']}'),
              if (payment['screenshotUrl'] != null)
                GestureDetector(
                  onTap: () {
                    _showImageDialog(context, payment['screenshotUrl']);
                  },
                  child: Text(
                    'View Screenshot',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
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
