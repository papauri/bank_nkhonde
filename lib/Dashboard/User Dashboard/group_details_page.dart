import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'member_list_tile.dart';
import 'user_payment_page.dart'; // Import the new payment page
import 'user_payment_details_page.dart'; // Import for navigating to payment details
import 'seed_money_payment_page.dart'; // Import the Seed Money Payment Page
import 'apply_for_loan_page.dart'; // Import Apply for Loan Page
import 'users_loan_details_page.dart'; // Import User's Loan Details Page
import 'total_contributions_tile.dart'; // Import Total Contributions Tile

class GroupDetailsPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String userId;

  GroupDetailsPage(
      {required this.groupId, required this.groupName, required this.userId});

  @override
  _GroupDetailsPageState createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  double amountOwedForMonth = 0.0;
  double amountPaidForMonth = 0.0;
  double fixedAmount = 0.0;
  double seedMoneyAmount = 0.0;
  double seedMoneyPaid = 0.0;
  List<Map<String, dynamic>> members = [];
  double pendingPayments = 0.0;
  bool hasLoanApplication = false;
  double loanAmount = 0.0;
  String loanStatus = '';
  DateTime? dueDate;
  double totalInterest = 0.0;
  double loanRepayments = 0.0;
  double quarterlyPayments = 0.0;
  double penaltiesPaid = 0.0;
  double approvedLoansForMonth = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
    _fetchUserFinancialData();
    _fetchUserLoanData();
  }

  Future<void> _fetchGroupData() async {
    try {
      DocumentSnapshot groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupDoc.exists) {
        var data = groupDoc.data() as Map<String, dynamic>;
        setState(() {
          fixedAmount = (data['fixedAmount'] ?? 0.0).toDouble();
          seedMoneyAmount = (data['seedMoney'] ?? 0.0).toDouble();
          members = List<Map<String, dynamic>>.from(data['members'] ?? []);
          totalInterest = (data['totalInterest'] ?? 0.0).toDouble();
          loanRepayments = (data['loanRepayments'] ?? 0.0).toDouble();
          quarterlyPayments = (data['quarterlyPayments'] ?? 0.0).toDouble();
          penaltiesPaid = (data['penaltiesPaid'] ?? 0.0).toDouble();
          approvedLoansForMonth =
              (data['approvedLoansForMonth'] ?? 0.0).toDouble();
        });
      }
    } catch (e) {
      print('Error fetching group data: $e');
    }
  }

  Future<void> _fetchUserFinancialData() async {
    try {
      QuerySnapshot confirmedPaymentsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('userId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'confirmed')
          .get();

      double totalPaid = 0.0;
      double totalSeedPaid = 0.0;
      for (var doc in confirmedPaymentsSnapshot.docs) {
        if (doc['paymentType'] == 'Seed Money') {
          totalSeedPaid += (doc['amount'] as num).toDouble();
        } else {
          totalPaid += (doc['amount'] as num).toDouble();
        }
      }

      QuerySnapshot pendingPaymentsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('payments')
          .where('userId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'pending')
          .get();

      double totalPending = 0.0;
      for (var doc in pendingPaymentsSnapshot.docs) {
        totalPending += (doc['amount'] as num).toDouble();
      }

      double totalOwed = fixedAmount - totalPaid;
      if (totalOwed < 0) totalOwed = 0.0;

      setState(() {
        amountPaidForMonth = totalPaid;
        amountOwedForMonth = totalOwed;
        pendingPayments = totalPending;
        seedMoneyPaid = totalSeedPaid;
      });
    } catch (e) {
      print('Error fetching user financial data: $e');
    }
  }

Future<void> _fetchUserLoanData() async {
  try {
    QuerySnapshot loanSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('loans')
        .where('userId', isEqualTo: widget.userId)
        .get();

    if (loanSnapshot.docs.isNotEmpty) {
      var loanData = loanSnapshot.docs.first.data() as Map<String, dynamic>;

      setState(() {
        hasLoanApplication = true;
        loanAmount = (loanData['amount'] ?? 0.0).toDouble();
        loanStatus = loanData['status'] ?? 'Pending';

        // Check if 'dueDate' exists and is not null
        if (loanData['dueDate'] != null) {
          dueDate = (loanData['dueDate'] as Timestamp).toDate();
        } else {
          // If 'dueDate' is null, set it to a default date or handle accordingly
          dueDate = DateTime.now(); // Or set it to null or handle it another way
        }
      });
    }
  } catch (e) {
    print('Error fetching user loan data: $e');
  }
}


@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(
        widget.groupName,
        style: TextStyle(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
    ),
    body: RefreshIndicator(
      onRefresh: () async {
        await _fetchGroupData();
        await _fetchUserFinancialData();
        await _fetchUserLoanData();
      },
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        children: [
          Text(
            'Financial Overview',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),

          _buildMonthlyFinancialOverview(),
          SizedBox(height: 16),
          
          _buildSeedMoneyOverview(),
          SizedBox(height: 16),

          // Corrected TotalContributionsTile
          TotalContributionsTile(
            groupId: widget.groupId, // Only pass the groupId
          ),
          
          SizedBox(height: 16),

          // Move the loan details tile here, above Apply for Loan and Make Payment buttons
          if (hasLoanApplication) ...[
            SizedBox(height: 16),
            _buildUserLoanDetailsTile(),
          ],

          SizedBox(height: 32),
          
          // Apply for Loan button after the loan details tile
          _buildApplyForLoanButton(Colors.blueGrey[800]!),
          SizedBox(height: 16),

          // Make Payment button
          _buildPaymentButton(Colors.blueGrey[800]!),
          SizedBox(height: 16),

          // Pending Payments section if applicable
          if (pendingPayments > 0) ...[
            SizedBox(height: 16),
            _buildPendingPaymentsTile(),
          ],

          SizedBox(height: 32),

          // Group Members section at the bottom
          Text(
            'Group Members',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          _buildMembersList(),
        ],
      ),
    ),
  );
}


Widget _buildUserLoanDetailsTile() {
  // Calculate loan approved date (assuming it's 3 months before dueDate)
  DateTime loanApprovedDate = dueDate != null ? dueDate!.subtract(Duration(days: 90)) : DateTime.now(); 
  DateTime nextPaymentDueDate = DateTime(loanApprovedDate.year, loanApprovedDate.month, 30); 

  // Calculate final due date (end of 3rd month)
  DateTime finalDueDate = DateTime(
      loanApprovedDate.year, loanApprovedDate.month + 3, 0); 

  // Update next payment date to end of the current month
  nextPaymentDueDate = DateTime(
      loanApprovedDate.year, loanApprovedDate.month + 1, 0);

  bool isApproved = loanStatus == 'approved';

  return GestureDetector(
    onTap: () {
      // Navigate to user's loan details page
      if (isApproved) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UsersLoanDetailsPage(
                groupId: widget.groupId, userId: widget.userId),
          ),
        );
      }
    },
    child: Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loan Amount',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'MWK ${loanAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18, color: Colors.orange),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$loanStatus',
                    style: TextStyle(
                      fontSize: 18,
                      color: isApproved ? Colors.green : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isApproved) ...[
            SizedBox(height: 16),
            Divider(color: Colors.grey[300]),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Final Loan Due Date',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${finalDueDate.day}/${finalDueDate.month}/${finalDueDate.year}',
                      style: TextStyle(fontSize: 16, color: Colors.redAccent),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Next Payment Due Date',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${nextPaymentDueDate.day}/${nextPaymentDueDate.month}/${nextPaymentDueDate.year}',
                      style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            SizedBox(height: 16),
            Divider(color: Colors.grey[300]),
            Center(
              child: Text(
                'Your loan is still pending approval.',
                style: TextStyle(fontSize: 16, color: Colors.redAccent),
              ),
            ),
          ],
          SizedBox(height: 16),
          if (isApproved) ...[
            Divider(color: Colors.grey[300]),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Tap to view details or make a payment',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

double _calculateNextPayment() {
  // Replace this with actual logic for next payment calculation if applicable
  return loanAmount / 3; // Example: Dividing the loan into 3 installments
}



  Widget _buildMonthlyFinancialOverview() {
    return GestureDetector(
      onTap: () {
        // Navigate to user payment details page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentDetailsPage(
                groupId: widget.groupId, userId: widget.userId),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount Owed for the Month',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'MWK ${amountOwedForMonth.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, color: Colors.orange),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Amount Paid',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'MWK ${amountPaidForMonth.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeedMoneyOverview() {
    double seedMoneyBalance = seedMoneyAmount - seedMoneyPaid;
    return GestureDetector(
      onTap: () {
        // Navigate to Seed Money Payment Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SeedMoneyPaymentPage(groupId: widget.groupId),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seed Money Payment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'MWK ${seedMoneyPaid.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, color: Colors.green),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Balance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'MWK ${seedMoneyBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    color: seedMoneyBalance > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingPaymentsTile() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
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
            'Pending Payments',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'MWK ${pendingPayments.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 18, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

Widget _buildApplyForLoanButton(Color primaryColor) {
  return ElevatedButton(
    onPressed: () async {
      try {
        // Fetch loan details before navigating
        Map<String, dynamic> loanDetails = await _fetchLoanDetails();

        // Navigate to Apply for Loan Page with all required parameters
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ApplyForLoanPage(
              groupId: widget.groupId,
              userId: widget.userId,
              loanAmount: loanDetails['loanAmount'] ?? 0.0,        // Pass fetched loan amount or default
              interestRate: loanDetails['interestRate'] ?? 0.0,    // Pass fetched interest rate or default
              repaymentPeriod: loanDetails['repaymentPeriod'] ?? 3, // Default repayment period
              outstandingBalance: loanDetails['outstandingBalance'] ?? 0.0, // Pass outstanding balance or default
            ),
          ),
        );
      } catch (e) {
        // Handle the error and show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch loan details')),
        );
      }
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      padding: EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: Text(
      'Apply for Loan',
      style: TextStyle(fontSize: 18, color: Colors.white),
    ),
  );
}


// Method to fetch loan details or set default values if not available
Future<Map<String, dynamic>> _fetchLoanDetails() async {
  try {
    // Query Firestore to check if the user already has a loan
    var loanSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('loans')
        .where('userId', isEqualTo: widget.userId)
        .get();

    if (loanSnapshot.docs.isNotEmpty) {
      // Loan exists, return loan details
      var loanData = loanSnapshot.docs.first.data() as Map<String, dynamic>;
      return {
        'loanAmount': loanData['amount'] ?? 0.0,
        'interestRate': loanData['interestRate'] ?? 0.0,
        'repaymentPeriod': loanData['repaymentPeriod'] ?? 3,
      };
    } else {
      // No loan exists, return default values
      return {
        'loanAmount': 0.0,
        'interestRate': 0.0,
        'repaymentPeriod': 3,
        'outstandingBalance': 0.0,
      };
    }
  } catch (e) {
    print('Error fetching loan details: $e');
    throw Exception('Loan data not found');
  }
}



  Widget _buildPaymentButton(Color primaryColor) {
    return ElevatedButton(
      onPressed: () {
        // Navigate to PaymentPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentPage(groupId: widget.groupId),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        'Make a Payment',
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }

  Widget _buildMembersList() {
    if (members.isEmpty) {
      return Center(child: Text('No members found.'));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: members.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        final member = members[index];
        return MemberListTile(
          name: member['name'] ?? 'Unnamed',
          profilePictureUrl: member['profilePicture'],
          memberId: member['userId'],
        );
      },
    );
  }
}
