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
  String? selectedPayerName;
  double fixedAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchFixedAmount();
  }

  Future<void> _fetchFixedAmount() async {
    try {
      // Fetch the fixedAmount directly from the group document
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupSnapshot.exists) {
        setState(() {
          fixedAmount = (groupSnapshot.data() as Map<String, dynamic>)['fixedAmount']?.toDouble() ?? 0.0;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group document does not exist.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch fixed amount: $e')),
      );
    }
  }

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

            // Extract unique payer names for dropdown
            final payerNames = payments
                .map((payment) => payment['payerName'])
                .toSet()
                .toList();

            // Filter payments by selected payer, if any
            final filteredPayments = selectedPayerName == null
                ? payments
                : payments.where((payment) => payment['payerName'] == selectedPayerName).toList();

            // Group payments by year, then by month
            Map<String, Map<String, List<QueryDocumentSnapshot>>> groupedPayments = {};
            for (var payment in filteredPayments) {
              final paymentDate = (payment['paymentDate'] as Timestamp).toDate();
              String year = DateFormat('yyyy').format(paymentDate);
              String month = DateFormat('MMMM').format(paymentDate);

              groupedPayments[year] = groupedPayments[year] ?? {};
              groupedPayments[year]![month] = groupedPayments[year]![month] ?? [];
              groupedPayments[year]![month]!.add(payment);
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButton<String>(
                    hint: Text('Filter by Member (optional)'),
                    value: selectedPayerName,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('Show All Members'),
                      ),
                      ...payerNames.map((payerName) {
                        return DropdownMenuItem<String>(
                          value: payerName,
                          child: Text(payerName),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedPayerName = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: groupedPayments.entries.map((yearEntry) {
                      return _buildYearSection(yearEntry.key, yearEntry.value);
                    }).toList(),
                  ),
                ),
              ],
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
    // Calculate total confirmed payment for each user
    Map<String, double> userTotalPayments = {};
    for (var payment in payments) {
      String payerName = payment['payerName'] ?? 'Unknown';
      double amount = payment['amount']?.toDouble() ?? 0.0;
      userTotalPayments[payerName] = (userTotalPayments[payerName] ?? 0.0) + amount;
    }

    return ExpansionTile(
      title: Text(
        '$month',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      children: [
        ...userTotalPayments.entries.map((entry) {
          String payerName = entry.key;
          double totalPaid = entry.value;
          double balance = fixedAmount - totalPaid;

          return Column(
            children: [
              ListTile(
                title: Text(
                  'Payer: $payerName - Total Paid: MWK ${totalPaid.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Balance: MWK ${balance.toStringAsFixed(2)}',
                  style: TextStyle(color: balance > 0 ? Colors.red : Colors.green),
                ),
              ),
              ...payments.where((payment) => payment['payerName'] == payerName).map((payment) {
                String paymentDateFormatted =
                    DateFormat('dd MMM yyyy').format((payment['paymentDate'] as Timestamp).toDate());
                return ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('MWK ${payment['amount']}'),
                  subtitle: Text(
                    'Date: $paymentDateFormatted\nReference: ${payment['transactionReference'] ?? 'N/A'}',
                  ),
                  trailing: payment['screenshotUrl'] != null
                      ? IconButton(
                          icon: Icon(Icons.image, color: Colors.blue),
                          onPressed: () => _showImageDialog(context, payment['screenshotUrl']),
                        )
                      : null,
                );
              }).toList(),
            ],
          );
        }).toList(),
      ],
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Payment Screenshot',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Image.network(imageUrl),
              ],
            ),
          ),
        );
      },
    );
  }
}
