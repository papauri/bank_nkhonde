import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class SubmitPaymentLogic {
  final String groupId;
  final String payerName;
  final String selectedPaymentType;
  final String? selectedMonth;
  final String transactionReference;
  final double amount;
  final File? screenshot; // New field to handle screenshot

  SubmitPaymentLogic({
    required this.groupId,
    required this.payerName,
    required this.selectedPaymentType,
    required this.transactionReference,
    required this.amount,
    this.selectedMonth,
    this.screenshot,
  });

  Future<void> submitPayment() async {
    if (amount <= 0 || transactionReference.isEmpty) {
      throw Exception('Invalid payment details. Please enter all required fields.');
    }

    String? screenshotUrl;
    if (screenshot != null) {
      // Upload the screenshot to Firebase Storage
      String filePath = 'payments_screenshots/${FirebaseAuth.instance.currentUser?.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      UploadTask uploadTask = FirebaseStorage.instance.ref().child(filePath).putFile(screenshot!);
      TaskSnapshot snapshot = await uploadTask;
      screenshotUrl = await snapshot.ref.getDownloadURL();
    }

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('payments')
          .add({
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'payerName': payerName,
        'amount': amount,
        'paymentType': selectedPaymentType,
        'transactionReference': transactionReference,
        'status': 'pending', // Admin will manually confirm payment
        'paymentDate': Timestamp.now(),
        if (selectedPaymentType == 'Past Payment') 'month': selectedMonth,
        'screenshotUrl': screenshotUrl, // Add the screenshot URL to the payment details
      });
    } catch (e) {
      throw Exception('Payment submission failed: $e');
    }
  }
}
