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
              .where('status', isEqualTo: 'confirmed')
              .where('paymentType', isEqualTo: 'Monthly Contribution') // Only monthly contributions
              .orderBy('paymentDate', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final payments = snapshot.data!.docs;
            if (payments.isEmpty) {
              return Center(
                child: Text('No confirmed monthly contributions found.'),
              );
            }

            // Group payments by year, then by month
            Map<String, Map<String, List<QueryDocumentSnapshot>>> groupedPayments = {};
            for (var payment in payments) {
              final paymentDate = (payment['paymentDate'] as Timestamp).toDate();
              String year = DateFormat('yyyy').format(paymentDate);
              String month = DateFormat('MMMM').format(paymentDate);

              groupedPayments[year] = groupedPayments[year] ?? {};
              groupedPayments[year]![month] = groupedPayments[year]![month] ?? [];
              groupedPayments[year]![month]!.add(payment);
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

  Widget _buildYearSection(String year, Map<String, List<QueryDocumentSnapshot>> paymentsByMonth) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
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

  Widget _buildMonthSection(String month, List<QueryDocumentSnapshot> payments) {
    double totalAmount = payments.fold(0.0, (sum, payment) => sum + (payment['amount']?.toDouble() ?? 0.0));
    return ExpansionTile(
      title: Text(
        '$month - Total: MWK ${totalAmount.toStringAsFixed(2)}',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      children: payments.map((payment) {
        String paymentDateFormatted = DateFormat('dd MMM yyyy').format((payment['paymentDate'] as Timestamp).toDate());
        return ListTile(
          leading: Icon(Icons.check_circle, color: Colors.green),
          title: Text('MWK ${payment['amount']}'),
          subtitle: Text('Date: $paymentDateFormatted\nReference: ${payment['transactionReference'] ?? 'N/A'}'),
          trailing: payment['screenshotUrl'] != null
              ? IconButton(
                  icon: Icon(Icons.image, color: Colors.blue),
                  onPressed: () => _showImageDialog(context, payment['screenshotUrl']),
                )
              : null,
        );
      }).toList(),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.network(imageUrl),
          ),
        );
      },
    );
  }
}
