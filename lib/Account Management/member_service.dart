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
    // Create user in Firebase Authentication
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    User? user = userCredential.user;

    if (user != null) {
      // Add member to the 'groups' collection with default values
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

      // Add user to 'users' collection with default profilePicture
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': memberName,
        'contact': memberContact,
        'email': email,
        'role': isAdmin ? 'admin' : 'user',
        'profilePicture': '',  // Set default empty profilePicture
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
    // Remove the old member record from the group
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .update({
      'members': FieldValue.arrayRemove([oldMember])
    });

    // Add updated member details to the group
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

    // Update the user's document in 'users' collection
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

  // Delete a member from Firebase Auth, 'groups', and 'users' collections
  static Future<void> deleteMember(String memberId, Map<String, dynamic> member, String groupId) async {
    // Remove the member from the 'groups' collection
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .update({
      'members': FieldValue.arrayRemove([member])
    });

    // Delete the user document from the 'users' collection
    await FirebaseFirestore.instance.collection('users').doc(memberId).delete();

    // Delete the user from Firebase Authentication using the Firebase Admin SDK
    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (e) {
      print('Error deleting user from Firebase Auth: $e');
    }
  }
}
