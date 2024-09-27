import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaymentManagementPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  PaymentManagementPage({required this.groupId, required this.groupName});

  @override
  _PaymentManagementPageState createState() => _PaymentManagementPageState();
}

class _PaymentManagementPageState extends State<PaymentManagementPage> {
  int? _expandedTileIndex;

  Future<void> _refreshPayments() async {
    setState(() {}); // Trigger UI refresh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Management'),
        backgroundColor: Colors.teal[800], // Stylish background color
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPayments,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .collection('payments')
              .orderBy('paymentDate', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final payments = snapshot.data!.docs;
            if (payments.isEmpty) {
              return Center(child: Text('No payments found.'));
            }

            // Group payments by status, month, and user
            Map<String, Map<String, Map<String, List<QueryDocumentSnapshot>>>> groupedPayments = {};

            for (var payment in payments) {
              final paymentDate = (payment['paymentDate'] as Timestamp).toDate();
              String monthYear = DateFormat('MMMM yyyy').format(paymentDate);
              String status = payment['status'];
              String payerName = payment['payerName'];

              groupedPayments[status] = groupedPayments[status] ?? {};
              groupedPayments[status]![monthYear] = groupedPayments[status]![monthYear] ?? {};
              groupedPayments[status]![monthYear]![payerName] = groupedPayments[status]![monthYear]![payerName] ?? [];
              groupedPayments[status]![monthYear]![payerName]!.add(payment);
            }

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildPaymentSection('Pending Payments', groupedPayments['pending'], Icons.pending_actions, Colors.orange),
                _buildPaymentSection('Confirmed Payments', groupedPayments['confirmed'], Icons.check_circle, Colors.green),
                _buildPaymentSection('Rejected Payments', groupedPayments['rejected'], Icons.cancel, Colors.redAccent),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaymentSection(String title, Map<String, Map<String, List<QueryDocumentSnapshot>>>? paymentsByMonth, IconData icon, Color statusColor) {
    if (paymentsByMonth == null || paymentsByMonth.isEmpty) {
      return Container(); // Hide if empty
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: statusColor, size: 30),
        title: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor),
        ),
        children: paymentsByMonth.entries.map((monthEntry) {
          String monthYear = monthEntry.key;
          Map<String, List<QueryDocumentSnapshot>> paymentsByUser = monthEntry.value;

          return _buildMonthSection(monthYear, paymentsByUser);
        }).toList(),
      ),
    );
  }

  Widget _buildMonthSection(String monthYear, Map<String, List<QueryDocumentSnapshot>> paymentsByUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.teal[50],
          child: Text(
            monthYear,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        ...paymentsByUser.entries.map((userEntry) {
          String payerName = userEntry.key;
          List<QueryDocumentSnapshot> userPayments = userEntry.value;

          return ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal[100],
              child: Icon(Icons.person, color: Colors.teal[800]),
            ),
            title: Text(
              payerName,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            initiallyExpanded: _expandedTileIndex == userPayments.hashCode,
            onExpansionChanged: (expanded) {
              setState(() {
                _expandedTileIndex = expanded ? userPayments.hashCode : null;
              });
            },
            children: userPayments.map((payment) {
              return ListTile(
                leading: Icon(
                  payment['status'] == 'confirmed' ? Icons.check_circle : Icons.pending,
                  color: payment['status'] == 'confirmed' ? Colors.green : Colors.orange,
                ),
                title: Text('MWK ${payment['amount']}'),
                subtitle: Text(
                  'Payment Date: ${_formatDate(payment['paymentDate'])}',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: _buildPaymentActions(payment),
              );
            }).toList(),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPaymentActions(QueryDocumentSnapshot payment) {
    if (payment['status'] == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.green),
            onPressed: () {
              _confirmPayment(payment.id, payment['amount'], payment['payerName']);
            },
            tooltip: 'Confirm Payment',
          ),
          IconButton(
            icon: Icon(Icons.cancel, color: Colors.red),
            onPressed: () {
              _rejectPaymentDialog(payment.id);
            },
            tooltip: 'Reject Payment',
          ),
        ],
      );
    } else {
      return Text(
        payment['status'] == 'confirmed' ? 'Confirmed' : 'Rejected',
        style: TextStyle(color: payment['status'] == 'confirmed' ? Colors.green : Colors.redAccent),
      );
    }
  }

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('EEEE, MMM d, yyyy').format(date);
  }

  void _confirmPayment(String paymentId, double amount, String payerName) async {
    try {
      DocumentReference groupDoc = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId);

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .doc(paymentId)
          .update({
        'status': 'confirmed',
      });

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot groupSnapshot = await transaction.get(groupDoc);

        if (groupSnapshot.exists) {
          double currentTotalContributions = groupSnapshot['totalContributions']?.toDouble() ?? 0.0;

          double updatedTotalContributions = currentTotalContributions + amount;

          transaction.update(groupDoc, {
            'totalContributions': updatedTotalContributions,
          });

          transaction.set(groupDoc.collection('confirmedPayments').doc(), {
            'payerName': payerName,
            'amount': amount,
            'confirmedAt': Timestamp.now(),
          });
        }
      });

      _refreshPayments();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment confirmed and contributions updated!')),
      );
    } catch (e) {
      print("Error confirming payment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to confirm payment.')),
      );
    }
  }

  void _rejectPayment(String paymentId, String reason) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .doc(paymentId)
          .update({
        'status': 'rejected',
        'reason': reason,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment rejected successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject payment. Try again.')),
      );
    }
  }

  void _rejectPaymentDialog(String paymentId) {
  final TextEditingController _reasonController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Reject Payment'),
        content: TextField(
          controller: _reasonController,
          decoration: InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Enter the reason for rejecting this payment',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _rejectPayment(paymentId, _reasonController.text.trim());
              Navigator.pop(context); // Close dialog after rejection
            },
            child: Text('Reject Payment'),
          ),
        ],
      );
    },
  );
}
}