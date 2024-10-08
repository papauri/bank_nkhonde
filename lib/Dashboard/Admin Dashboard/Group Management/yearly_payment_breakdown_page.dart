import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class YearlyPaymentBreakdownPage extends StatelessWidget {
  final String groupId;

  const YearlyPaymentBreakdownPage({required this.groupId});

  Future<Map<String, dynamic>> _fetchYearlyPayments() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('payments')
        .where('status', isEqualTo: 'confirmed')
        .get();

    DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .get();
    double interestRate = (groupSnapshot['interestRate'] ?? 0.2).toDouble();

    Map<String, double> memberContributions = {};
    Map<String, double> loansTaken = {};
    Map<String, double> interestAccrued = {};
    Map<String, double> seedMoney = {};
    Map<String, double> outstandingSeedMoney = {};
    Map<String, List<Map<String, dynamic>>> monthlyBreakdown = {};
    Map<String, List<Map<String, dynamic>>> seedMoneyBreakdown = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      String payerName = data['payerName'] ?? 'Unnamed';
      double amount = (data['amount'] ?? 0).toDouble();
      String paymentType = data['paymentType'] ?? '';
      String status = data['status'] ?? '';
      DateTime paymentDate = (data['paymentDate'] as Timestamp).toDate();
      String monthYear = DateFormat('MMMM yyyy').format(paymentDate);

      if (status == 'confirmed') {
        if (paymentType == 'Monthly Contribution') {
          memberContributions[payerName] = (memberContributions[payerName] ?? 0) + amount;

          // Add payment to monthly breakdown
          if (!monthlyBreakdown.containsKey(payerName)) {
            monthlyBreakdown[payerName] = [];
          }
          monthlyBreakdown[payerName]!.add({
            'monthYear': monthYear,
            'amount': amount,
            'paymentDate': DateFormat('dd MMM yyyy').format(paymentDate),
          });
        } else if (paymentType == 'loan') {
          loansTaken[payerName] = (loansTaken[payerName] ?? 0) + amount;
          double interest = amount * interestRate;
          interestAccrued[payerName] = (interestAccrued[payerName] ?? 0) + interest;
        } else if (paymentType == 'Seed Money') {
          seedMoney[payerName] = (seedMoney[payerName] ?? 0) + amount;
          double outstanding = 1000.0 - seedMoney[payerName]!;
          outstandingSeedMoney[payerName] = outstanding > 0 ? outstanding : 0;

          // Add seed money to seed money breakdown
          if (!seedMoneyBreakdown.containsKey(payerName)) {
            seedMoneyBreakdown[payerName] = [];
          }
          seedMoneyBreakdown[payerName]!.add({
            'monthYear': monthYear,
            'amount': amount,
            'paymentDate': DateFormat('dd MMM yyyy').format(paymentDate),
          });
        }
      }
    }

    return {
      'memberContributions': memberContributions,
      'loansTaken': loansTaken,
      'interestAccrued': interestAccrued,
      'seedMoney': seedMoney,
      'outstandingSeedMoney': outstandingSeedMoney,
      'monthlyBreakdown': monthlyBreakdown,
      'seedMoneyBreakdown': seedMoneyBreakdown,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yearly Contribution Summary'),
        backgroundColor: Colors.teal[800],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchYearlyPayments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSummaryTable(
                  context,
                  'Monthly Contributions for the Year',
                  data['memberContributions'],
                  'Total Contribution (MWK)',
                  monthlyBreakdown: data['monthlyBreakdown'],
                ),
                SizedBox(height: 20),
                _buildSummaryTable(
                  context,
                  'Loans Taken and Interest Accrued',
                  data['loansTaken'],
                  'Total Loan Amount (MWK)',
                  additionalColumnData: data['interestAccrued'],
                  additionalColumnTitle: 'Interest Accrued (MWK)',
                ),
                SizedBox(height: 20),
                _buildSummaryTable(
                  context,
                  'Seed Money Collected',
                  data['seedMoney'],
                  'Total Seed Money (MWK)',
                  additionalColumnData: data['outstandingSeedMoney'],
                  additionalColumnTitle: 'Outstanding Balance (MWK)',
                  seedMoneyBreakdown: data['seedMoneyBreakdown'],
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _exportToExcel(context, data),
                  icon: Icon(Icons.download),
                  label: Text('Download Excel'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryTable(
    BuildContext context,
    String title,
    Map<String, double> data,
    String firstColumnTitle, {
    Map<String, double>? additionalColumnData,
    String? additionalColumnTitle,
    Map<String, List<Map<String, dynamic>>>? monthlyBreakdown,
    Map<String, List<Map<String, dynamic>>>? seedMoneyBreakdown,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10),
          color: Colors.teal[50],
          width: double.infinity,
          child: Center(
            child: Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.teal, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.teal[100]),
              columnSpacing: 16,
              horizontalMargin: 16,
              columns: [
                DataColumn(label: Text('Member', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(firstColumnTitle, style: TextStyle(fontWeight: FontWeight.bold))),
                if (additionalColumnData != null && additionalColumnTitle != null)
                  DataColumn(label: Text(additionalColumnTitle, style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: data.entries.map((entry) {
                return DataRow(cells: [
                  DataCell(
                    GestureDetector(
                      onTap: () {
                        if (monthlyBreakdown != null && monthlyBreakdown.containsKey(entry.key)) {
                          _showContributionDetails(context, entry.key, monthlyBreakdown[entry.key]!);
                        } else if (seedMoneyBreakdown != null && seedMoneyBreakdown.containsKey(entry.key)) {
                          _showContributionDetails(context, entry.key, seedMoneyBreakdown[entry.key]!);
                        }
                      },
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text('MWK ${entry.value.toStringAsFixed(2)}')),
                  if (additionalColumnData != null && additionalColumnTitle != null)
                    DataCell(Text('MWK ${additionalColumnData[entry.key]?.toStringAsFixed(2) ?? '0.00'}')),
                ]);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _showContributionDetails(BuildContext context, String memberName, List<Map<String, dynamic>> contributions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Contributions by $memberName',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: contributions.length,
                      itemBuilder: (context, index) {
                        final contribution = contributions[index];
                        return ListTile(
                          title: Text('MWK ${contribution['amount']}'),
                          subtitle: Text('Date: ${contribution['paymentDate']}'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _exportToExcel(BuildContext context, Map<String, dynamic> data) async {
    var workbook = excel.Excel.createExcel();
    excel.Sheet sheet = workbook['Yearly Payments'];

    sheet.appendRow([
      'Member',
      'Total Contribution (MWK)',
      'Total Loan Amount (MWK)',
      'Interest Accrued (MWK)',
      'Total Seed Money (MWK)',
      'Outstanding Seed Balance (MWK)',
    ]);

    data['memberContributions'].forEach((member, totalContribution) {
      double loans = data['loansTaken'][member] ?? 0.0;
      double interest = data['interestAccrued'][member] ?? 0.0;
      double seed = data['seedMoney'][member] ?? 0.0;
      double outstandingSeed = data['outstandingSeedMoney'][member] ?? 0.0;
      sheet.appendRow([member, totalContribution, loans, interest, seed, outstandingSeed]);
    });

    excel.Sheet monthlySheet = workbook['Monthly Contributions'];
    monthlySheet.appendRow(['Member', 'Month', 'Amount', 'Payment Date']);

    data['monthlyBreakdown'].forEach((member, contributions) {
      for (var contribution in contributions) {
        monthlySheet.appendRow([
          member,
          contribution['monthYear'],
          contribution['amount'],
          contribution['paymentDate'],
        ]);
      }
    });

    try {
      if (await Permission.storage.request().isGranted) {
        Directory? directory;

        if (Platform.isAndroid) {
          directory = await getExternalStorageDirectory();
          String newPath = "";
          List<String> paths = directory!.path.split("/");
          for (int i = 1; i < paths.length; i++) {
            String folder = paths[i];
            if (folder != "Android") {
              newPath += "/" + folder;
            } else {
              break;
            }
          }
          newPath = newPath + "/BankNkhondeExports";
          directory = Directory(newPath);
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        String outputPath = '${directory.path}/YearlyPaymentBreakdown.xlsx';
        File(outputPath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(workbook.encode()!);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Excel file saved at $outputPath'),
          duration: Duration(seconds: 5),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Storage permission is required to save the Excel file.'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save Excel file: $e'),
      ));
    }
  }
}
