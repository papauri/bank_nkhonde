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
                      Text('Amount: \$${payment['amount']}'),
                      Text('Status: ${payment['status']}'),
                      Text('Payment Date: ${payment['paymentDate']}'),
                      Text('Loan ID: ${payment['loanId']}'),
                    ],
                  ),
                  trailing: payment['status'] == 'pending'
                      ? IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            _confirmPayment(payment.id);
                          },
                          tooltip: 'Confirm Payment',
                        )
                      : Text(payment['status'] == 'confirmed'
                          ? 'Confirmed'
                          : 'Pending'),
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

  void _confirmPayment(String paymentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .doc(paymentId)
          .update({
        'status': 'confirmed',
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
              Text('Amount: \$${payment['amount']}'),
              Text('Status: ${payment['status']}'),
              Text('Loan ID: ${payment['loanId']}'),
              Text('Payment Date: ${payment['paymentDate']}'),
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
        'Payer: ${payment['payerName']}\nAmount: \$${payment['amount']}\nStatus: ${payment['status']}\nPayment Date: ${payment['paymentDate']}\nLoan ID: ${payment['loanId']}';
    Clipboard.setData(ClipboardData(text: paymentInfo));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment info copied to clipboard!')),
    );
  }
}
