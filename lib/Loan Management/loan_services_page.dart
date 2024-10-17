import 'package:flutter/material.dart';
import '../Dashboard/User Dashboard/user_dashboard.dart';
import 'users_apply_for_loan_page.dart';
import 'loan_history_page.dart';
import 'active_loans_page.dart';
import 'pending_loans_page.dart';
import 'loan_calculator_page.dart'; // Import for loan calculator
import 'users_loan_repayment_page.dart'; // Import for loan repayment page
import '../Login Page/login_page.dart'; // Import for logout

class LoanServicesPage extends StatefulWidget {
  final String userId;
  final String groupId;

  LoanServicesPage({required this.userId, required this.groupId});

  @override
  _LoanServicesPageState createState() => _LoanServicesPageState();
}

class _LoanServicesPageState extends State<LoanServicesPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = []; // Loan-related pages

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      _buildLoanServicesPage(),
      PendingLoansPage(userId: widget.userId, groupId: widget.groupId),
      UserDashboard(isAdmin: false), // Back to the user dashboard
    ]);
  }

  void onTabTapped(int index) {
    if (index == 2) {
      // Navigate to Loan Calculator as a new page instead of a nested one
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoanCalculatorPage(groupId: widget.groupId),
        ),
      );
    } else if (index == 1) {
      // Navigate to Loan Repayment Page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoanRepaymentPage(
            userId: widget.userId,
            groupId: widget.groupId,
            loanAmount: 0.0, // Replace with actual data from the database
            interestRate: 0.0, // Replace with actual interest rate
            repaymentPeriod: 3, // Replace with actual repayment period
            outstandingBalance: 0.0, // Replace with actual outstanding balance
          ),
        ),
      );
    } else if (index == 3) {
      // Logout logic
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text('Logout'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loan Services', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Bottom Navigation Bar for Loan Services
  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      onTap: onTabTapped,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet),
          label: 'Loan Services',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.payment),
          label: 'Repay Loan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calculate),
          label: 'Loan Calculator', // Loan Calculator button
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.logout),
          label: 'Logout',
        ),
      ],
    );
  }

  // Loan Services Page with different loan-related options
  Widget _buildLoanServicesPage() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildTile(
          title: 'Active Loans',
          subtitle: 'View your active loans',
          icon: Icons.check_circle_outline,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActiveLoansPage(
                  userId: widget.userId,
                  groupId: widget.groupId,
                ),
              ),
            );
          },
        ),
        SizedBox(height: 16),
        _buildTile(
          title: 'Pending Loans',
          subtitle: 'Check your pending loan applications',
          icon: Icons.pending_actions,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PendingLoansPage(
                  userId: widget.userId,
                  groupId: widget.groupId,
                ),
              ),
            );
          },
        ),
        SizedBox(height: 16),
        _buildTile(
          title: 'Loan History',
          subtitle: 'View your loan history',
          icon: Icons.history,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoanHistoryPage(
                  userId: widget.userId,
                  groupId: widget.groupId,
                ),
              ),
            );
          },
        ),
        SizedBox(height: 16),
        _buildTile(
          title: 'Apply for a Loan',
          subtitle: 'Request a new loan',
          icon: Icons.add_circle_outline,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ApplyForLoanPage(
                  groupId: widget.groupId,
                  userId: widget.userId,
                  loanAmount: 0.0, // Placeholder
                  interestRate: 0.0, // Placeholder
                  repaymentPeriod: 3, // Placeholder
                  outstandingBalance: 0.0, // Placeholder
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Helper method for building tiles
  Widget _buildTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
          children: [
            Icon(icon, size: 40, color: Colors.blueAccent),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
