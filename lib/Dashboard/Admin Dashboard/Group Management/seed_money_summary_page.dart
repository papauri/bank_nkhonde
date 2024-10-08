import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeedMoneySummaryPage extends StatefulWidget {
  final String groupId;

  SeedMoneySummaryPage({required this.groupId});

  @override
  _SeedMoneySummaryPageState createState() => _SeedMoneySummaryPageState();
}

class _SeedMoneySummaryPageState extends State<SeedMoneySummaryPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> members = [];

  @override
  void initState() {
    super.initState();
    _fetchSeedMoneySummary();
  }

  Future<void> _fetchSeedMoneySummary() async {
    try {
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupSnapshot.exists) {
        List<dynamic> groupMembers = groupSnapshot['members'];
        List<Map<String, dynamic>> memberList = [];

        for (var member in groupMembers) {
          String memberId = member['userId'];

          QuerySnapshot<Map<String, dynamic>> memberPaymentSnapshot =
              await FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('payments')
                  .where('userId', isEqualTo: memberId)
                  .where('paymentType', isEqualTo: 'Seed Money')
                  .get();

          double totalPaid = 0.0;
          for (var payment in memberPaymentSnapshot.docs) {
            totalPaid += (payment['amount'] as num).toDouble();
          }

          memberList.add({
            'userId': memberId,
            'name': member['name'],
            'email': member['email'],
            'contact': member['contact'],
            'totalPaid': totalPaid,
            'isPaid': totalPaid >= groupSnapshot['seedMoney'],
            'seedMoneyAmount': groupSnapshot['seedMoney'],
            'payments': memberPaymentSnapshot.docs,
          });
        }

        setState(() {
          members = memberList;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching seed money summary: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _approvePayment(String paymentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .doc(paymentId)
          .update({'status': 'confirmed'});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment approved successfully!')),
      );

      // Refresh the summary after approval
      _fetchSeedMoneySummary();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve payment. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seed Money Summary'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: members.length,
              itemBuilder: (context, index) {
                return _buildMemberCard(members[index]);
              },
            ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    double balance = member['seedMoneyAmount'] - member['totalPaid'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              member['name'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            SizedBox(height: 8),
            Text('Email: ${member['email']}'),
            SizedBox(height: 4),
            Text('Contact: ${member['contact']}'),
            SizedBox(height: 4),
            Text(
              'Total Paid: MWK ${member['totalPaid'].toStringAsFixed(2)}',
              style: TextStyle(
                color: member['isPaid'] ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            if (!member['isPaid'])
              Text(
                'Balance: MWK ${balance.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            SizedBox(height: 12),
            ...member['payments'].map<Widget>((payment) {
              return _buildPaymentTile(payment);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTile(QueryDocumentSnapshot payment) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 2,
      child: ListTile(
        title: Text(
          'Payment: MWK ${(payment['amount'] as num).toStringAsFixed(2)}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date Paid: ${payment['paymentDate'].toDate()}'),
            Text('Reference: ${payment['transactionReference']}'),
          ],
        ),
        trailing: payment['status'] == 'pending'
            ? IconButton(
                icon: Icon(Icons.check, color: Colors.green),
                onPressed: () {
                  _approvePayment(payment.id);
                },
              )
            : Icon(Icons.check_circle, color: Colors.green),
        onTap: () {
          if (payment['screenshotUrl'] != null) {
            _showScreenshotDialog(payment['screenshotUrl']);
          }
        },
      ),
    );
  }

  void _showScreenshotDialog(String imageUrl) {
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
