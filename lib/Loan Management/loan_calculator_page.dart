import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; // For calculating interest

class LoanCalculatorPage extends StatefulWidget {
  final String groupId;

  LoanCalculatorPage({required this.groupId});

  @override
  _LoanCalculatorPageState createState() => _LoanCalculatorPageState();
}

class _LoanCalculatorPageState extends State<LoanCalculatorPage> {
  final TextEditingController _loanAmountController = TextEditingController();
  final TextEditingController _repaymentPeriodController = TextEditingController();

  double _interestRate = 0.0;
  double _penaltyRate = 0.0;
  double _monthlyPayment = 0.0;
  double _totalPayment = 0.0;
  double _penaltyAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchRates(); // Fetch rates on page load
  }

  Future<void> _fetchRates() async {
    try {
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      setState(() {
        _interestRate = (groupSnapshot['interestRate'] ?? 0.0).toDouble();
        _penaltyRate = (groupSnapshot['loanPenalty'] ?? 0.0).toDouble();
      });
    } catch (e) {
      print('Error fetching rates: $e');
    }
  }

  void _calculateLoanDetails() {
    double loanAmount = double.tryParse(_loanAmountController.text) ?? 0.0;
    int repaymentPeriod = int.tryParse(_repaymentPeriodController.text) ?? 0;

    if (loanAmount > 0 && repaymentPeriod > 0) {
      double monthlyInterestRate = _interestRate / 100 / 12;
      double denominator = pow(1 + monthlyInterestRate, repaymentPeriod) - 1;
      _monthlyPayment = loanAmount * monthlyInterestRate * pow(1 + monthlyInterestRate, repaymentPeriod) / denominator;

      _totalPayment = _monthlyPayment * repaymentPeriod;
      _penaltyAmount = _totalPayment * (_penaltyRate / 100);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loan Calculator', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTextField(
              controller: _loanAmountController,
              label: 'Loan Amount (MWK)',
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _repaymentPeriodController,
              label: 'Repayment Period (Months)',
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _calculateLoanDetails,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blueAccent,
              ),
              child: Text('Calculate', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            SizedBox(height: 24),
            if (_monthlyPayment > 0) ...[
              _buildResultTile(
                title: 'Monthly Payment',
                value: 'MWK ${_monthlyPayment.toStringAsFixed(2)}',
              ),
              _buildResultTile(
                title: 'Total Payment',
                value: 'MWK ${_totalPayment.toStringAsFixed(2)}',
              ),
              _buildResultTile(
                title: 'Penalty Amount',
                value: 'MWK ${_penaltyAmount.toStringAsFixed(2)}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required TextInputType keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildResultTile({required String title, required String value}) {
    return ListTile(
      contentPadding: EdgeInsets.all(16),
      title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: TextStyle(fontSize: 16, color: Colors.black)),
    );
  }
}
