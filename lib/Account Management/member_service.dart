import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemberService {
  // Add a new member
  static Future<void> addMember({
    required String groupId,
    required String memberName,
    required String memberContact,
    required String email,
    required String password,
    required bool isAdmin,
  }) async {
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    User? user = userCredential.user;

    if (user != null) {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .update({
        'members': FieldValue.arrayUnion([{
          'name': memberName,
          'contact': memberContact,
          'email': email,
          'userId': user.uid,
        }])
      });

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': memberName,
        'contact': memberContact,
        'email': email,
        'role': isAdmin ? 'admin' : 'user',
      });
    }
  }

  // Update an existing member
  static Future<void> updateMember({
    required String memberId,
    required String groupId,
    required String newName,
    required String newContact,
    required String newEmail,
    required String newRole,
    required Map<String, dynamic> oldMember,
  }) async {
    // Remove the old member record
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .update({
      'members': FieldValue.arrayRemove([oldMember])
    });

    // Add updated details
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .update({
      'members': FieldValue.arrayUnion([{
        'name': newName,
        'contact': newContact,
        'email': newEmail,
        'userId': memberId,
      }])
    });

    // Update user collection
    await FirebaseFirestore.instance
        .collection('users')
        .doc(memberId)
        .update({
      'name': newName,
      'contact': newContact,
      'email': newEmail,
      'role': newRole,
    });
  }

  // Delete a member
  static Future<void> deleteMember(String memberId, Map<String, dynamic> member, String groupId) async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .update({
      'members': FieldValue.arrayRemove([member])
    });
  }
}
