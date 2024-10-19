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

            // Group payments by payment type, month, and user
            Map<String, Map<String, Map<String, List<QueryDocumentSnapshot>>>>
                groupedPayments = {};

            for (var payment in payments) {
              final paymentDate =
                  (payment['paymentDate'] as Timestamp).toDate();
              String monthYear = DateFormat('MMMM yyyy').format(paymentDate);
              String paymentType = payment['paymentType'];

              // Check if 'payerName' exists, and provide a fallback if it's null
              Map<String, dynamic>? paymentData = payment.data()
                  as Map<String, dynamic>?; // Cast and check if null

              String payerName =
                  (paymentData != null && paymentData.containsKey('payerName'))
                      ? paymentData['payerName'] as String
                      : 'Unknown Payer'; // Fallback if 'payerName' is missing

              groupedPayments[paymentType] = groupedPayments[paymentType] ?? {};
              groupedPayments[paymentType]![monthYear] =
                  groupedPayments[paymentType]![monthYear] ?? {};
              groupedPayments[paymentType]![monthYear]![payerName] =
                  groupedPayments[paymentType]![monthYear]![payerName] ?? [];
              groupedPayments[paymentType]![monthYear]![payerName]!.add(payment);
            }

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildPaymentCategorySection('Seed Money Payments',
                    groupedPayments['Seed Money'], Colors.purple),
                _buildPaymentCategorySection('Quarterly Payments',
                    groupedPayments['Quarterly Payment'], Colors.teal),
                _buildPaymentCategorySection('Penalty Payments',
                    groupedPayments['Penalty'], Colors.red),
                _buildPaymentCategorySection('Monthly Contributions',
                    groupedPayments['Monthly Contribution'], Colors.blue),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaymentCategorySection(
      String title,
      Map<String, Map<String, List<QueryDocumentSnapshot>>>? paymentsByMonth,
      Color statusColor) {
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
        leading: Icon(Icons.payment, color: statusColor, size: 30),
        title: Text(
          title,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: statusColor),
        ),
        children: paymentsByMonth.entries.map((monthEntry) {
          String monthYear = monthEntry.key;
          Map<String, List<QueryDocumentSnapshot>> paymentsByUser =
              monthEntry.value;

          return _buildMonthSection(monthYear, paymentsByUser);
        }).toList(),
      ),
    );
  }

  Widget _buildMonthSection(String monthYear,
      Map<String, List<QueryDocumentSnapshot>> paymentsByUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.teal[50],
          child: Text(
            monthYear,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
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
                  payment['status'] == 'confirmed'
                      ? Icons.check_circle
                      : Icons.pending,
                  color: payment['status'] == 'confirmed'
                      ? Colors.green
                      : Colors.orange,
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MWK ${payment['amount']}'),
                    if (payment['transactionReference'] != null)
                      Text('Reference: ${payment['transactionReference']}'),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Date: ${_formatDate(payment['paymentDate'])}',
                      style: TextStyle(fontSize: 12),
                    ),
                    if (payment['screenshotUrl'] != null)
                      GestureDetector(
                        onTap: () {
                          _showImageDialog(
                              context, payment['screenshotUrl']);
                        },
                        child: Text(
                          'View Screenshot',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                  ],
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
              _confirmPayment(
                  payment.id, payment['amount'], payment['payerName']);
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
        style: TextStyle(
            color: payment['status'] == 'confirmed'
                ? Colors.green
                : Colors.redAccent),
      );
    }
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

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('EEEE, MMM d, yyyy').format(date);
  }

  void _confirmPayment(
      String paymentId, double amount, String payerName) async {
    try {
      DocumentReference groupDoc =
          FirebaseFirestore.instance.collection('groups').doc(widget.groupId);

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
          double currentTotalContributions =
              groupSnapshot['totalContributions']?.toDouble() ?? 0.0;

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
        SnackBar(content: Text('Failed to confirm payment. Please try again.')),
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

      _refreshPayments();
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
