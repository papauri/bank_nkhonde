import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditGroupParametersDialog extends StatelessWidget {
  final String groupId;
  final double seedMoney;
  final double interestRate;
  final double fixedAmount;
  final Function(double, double, double) onSave;

  const EditGroupParametersDialog({
    required this.groupId,
    required this.seedMoney,
    required this.interestRate,
    required this.fixedAmount,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController _seedMoneyController =
        TextEditingController(text: seedMoney.toString());
    final TextEditingController _interestRateController =
        TextEditingController(text: interestRate.toString());
    final TextEditingController _fixedAmountController =
        TextEditingController(text: fixedAmount.toString());

    return AlertDialog(
      title: Text('Edit Group Parameters'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            _buildParameterTextField(
              controller: _seedMoneyController,
              label: 'Seed Money (MWK)',
            ),
            _buildParameterTextField(
              controller: _interestRateController,
              label: 'Interest Rate (%)',
            ),
            _buildParameterTextField(
              controller: _fixedAmountController,
              label: 'Monthly Contribution (MWK)',
            ),
            SizedBox(height: 10),
            Text(
              'Changing these parameters will affect existing loans and contributions. Proceed with caution.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.black)),
        ),
        ElevatedButton(
          onPressed: () {
            final newSeedMoney = double.parse(_seedMoneyController.text);
            final newInterestRate = double.parse(_interestRateController.text);
            final newFixedAmount = double.parse(_fixedAmountController.text);
            _updateGroupParameters(
              groupId,
              newSeedMoney,
              newInterestRate,
              newFixedAmount,
              onSave,
              context,
            );
          },
          child: Text('Save Changes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildParameterTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }

  void _updateGroupParameters(
    String groupId,
    double newSeedMoney,
    double newInterestRate,
    double newFixedAmount,
    Function(double, double, double) onSave,
    BuildContext context,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
        'seedMoney': newSeedMoney,
        'interestRate': newInterestRate,
        'fixedAmount': newFixedAmount,
      });

      // Trigger the callback
      onSave(newSeedMoney, newInterestRate, newFixedAmount);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group parameters updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update group parameters. Try again.')),
      );
    }
  }
}
