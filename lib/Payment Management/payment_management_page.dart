import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class PaymentManagementPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  PaymentManagementPage({required this.groupId, required this.groupName});

  @override
  _PaymentManagementPageState createState() => _PaymentManagementPageState();
}

class _PaymentManagementPageState extends State<PaymentManagementPage> {
  Future<void> _refreshPayments() async {
    setState(() {}); // Trigger a UI refresh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Management'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPayments,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .collection('payments')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final payments = snapshot.data!.docs;
            if (payments.isEmpty) {
              return Center(child: Text('No payments found.'));
            }

            return ListView.builder(
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return ListTile(
                  title: Text('Payment from ${payment['payerName']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amount: MWK ${payment['amount']}'),
                      Text('Status: ${payment['status']}'),
                      Text('Payment Date: ${payment['paymentDate']}'),
                    ],
                  ),
                  trailing: payment['status'] == 'pending'
                      ? Row(
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
                        )
                      : Text(payment['status'] == 'confirmed'
                          ? 'Confirmed'
                          : 'Rejected'),
                  onTap: () {
                    _showPaymentDetails(context, payment);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

void _confirmPayment(String paymentId, double amount, String payerName) async {
  try {
    // Confirm the payment and update payment status to 'confirmed'
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('payments')
        .doc(paymentId)
        .update({
      'status': 'confirmed',
    });

    // Update total contributions in the group document
    DocumentReference groupDoc = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot groupSnapshot = await transaction.get(groupDoc);
      if (groupSnapshot.exists) {
        double currentTotalContributions =
            groupSnapshot['totalContributions']?.toDouble() ?? 0.0;
        transaction.update(groupDoc, {
          'totalContributions': currentTotalContributions + amount,
        });

        // Log confirmed payments in 'confirmedPayments' sub-collection
        transaction.set(groupDoc.collection('confirmedPayments').doc(), {
          'payerName': payerName,
          'amount': amount,
          'confirmedAt': Timestamp.now(),
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment confirmed successfully!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to confirm payment. Try again.')),
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
        'reason': reason, // Add the rejection reason
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
            decoration: InputDecoration(labelText: 'Reason for rejection'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _rejectPayment(paymentId, _reasonController.text.trim());
                Navigator.pop(context);
              },
              child: Text('Reject Payment'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentDetails(BuildContext context, QueryDocumentSnapshot payment) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Payment Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Payer: ${payment['payerName']}'),
              Text('Amount: MWK ${payment['amount']}'),
              Text('Status: ${payment['status']}'),
              Text('Payment Date: ${payment['paymentDate']}'),
              if (payment['status'] == 'rejected')
                Text('Rejection Reason: ${payment['reason']}'),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  _copyPaymentInfo(payment);
                },
                child: Text('Copy Payment Info'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _copyPaymentInfo(QueryDocumentSnapshot payment) {
    final paymentInfo =
        'Payer: ${payment['payerName']}\nAmount: MWK ${payment['amount']}\nStatus: ${payment['status']}\nPayment Date: ${payment['paymentDate']}';
    Clipboard.setData(ClipboardData(text: paymentInfo));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment info copied to clipboard!')),
    );
  }
}
