import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class QuarterlyPaymentPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  QuarterlyPaymentPage({required this.groupId, required this.groupName});

  @override
  _QuarterlyPaymentPageState createState() => _QuarterlyPaymentPageState();
}

class _QuarterlyPaymentPageState extends State<QuarterlyPaymentPage> {
  double quarterlyPaymentAmount = 0.0;
  List<Map<String, dynamic>> members = [];
  DateTime? nextDueDate;

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
    _fetchMembersData();
  }

  Future<void> _fetchGroupData() async {
  try {
    DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();

    if (groupSnapshot.exists) {
      print("Group Data: ${groupSnapshot.data()}"); // Add this line to print the fetched data
      setState(() {
        quarterlyPaymentAmount =
            (groupSnapshot['quarterlyPaymentAmount'] ?? 0.0).toDouble();
        nextDueDate = (groupSnapshot['nextDueDate'] as Timestamp?)?.toDate();
      });
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to fetch group data: $e')),
    );
  }
}

Future<void> _fetchMembersData() async {
  try {
    DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();

    if (groupSnapshot.exists) {
      var groupData = groupSnapshot.data() as Map<String, dynamic>;
      if (groupData.containsKey('members')) {
        List<dynamic> membersList = groupData['members'];
        setState(() {
          members = membersList.map((member) => {
                'userId': member['userId'],
                'name': member['name'] ?? 'Unnamed',
                'profilePicture': member['profilePicture'] ?? 'account_circle',
                'hasPaidQuarterly': member['hasPaidQuarterly'] ?? false,
              }).toList();
        });
      } else {
        print("No members found in the group data.");
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to fetch members data: $e')),
    );
  }
}


  void _sendNotifications() {
    for (var member in members) {
      if (!member['hasPaidQuarterly']) {
        // Simulated notification sending
        print('Sending notification to ${member['name']}');
      }
    }
  }

  void _setQuarterDates(DateTime startDate) {
    // Calculate quarter end dates for this group
    DateTime q1 = DateTime(startDate.year, 3, 31);
    DateTime q2 = DateTime(startDate.year, 6, 30);
    DateTime q3 = DateTime(startDate.year, 9, 30);
    DateTime q4 = DateTime(startDate.year, 12, 31);

    // Update the Firestore document with these dates
    FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .update({
      'quarterDates': [q1, q2, q3, q4].map((date) => date.toIso8601String()).toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quarterly Payments - ${widget.groupName}'),
        backgroundColor: Colors.teal,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchGroupData();
          await _fetchMembersData();
        },
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildQuarterlyPaymentInfo(),
            SizedBox(height: 16),
            _buildMembersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuarterlyPaymentInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quarterly Payment Amount',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Each member must pay MWK ${quarterlyPaymentAmount.toStringAsFixed(2)} per quarter.',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          if (nextDueDate != null) ...[
            SizedBox(height: 8),
            Text(
              'Next Due Date: ${DateFormat.yMMMd().format(nextDueDate!)}',
              style: TextStyle(fontSize: 16, color: Colors.redAccent),
            ),
          ],
          if (nextDueDate == null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: ElevatedButton(
                onPressed: () {
                  DateTime startDate = DateTime.now();
                  _setQuarterDates(startDate);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Quarterly dates have been set for the group.'),
                    ),
                  );
                },
                child: Text('Set Quarterly Dates'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: member['profilePicture'] == 'account_circle'
                  ? Icon(Icons.account_circle)
                  : Image.network(member['profilePicture']),
            ),
            title: Text(member['name']),
            subtitle: Text(
              member['hasPaidQuarterly']
                  ? 'Paid'
                  : 'Pending Payment',
              style: TextStyle(
                color: member['hasPaidQuarterly'] ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: member['hasPaidQuarterly']
                ? Icon(Icons.check_circle, color: Colors.green)
                : Icon(Icons.error, color: Colors.redAccent),
          ),
        );
      },
    );
  }
}
