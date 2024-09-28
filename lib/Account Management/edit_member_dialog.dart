import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditMemberDialog {
  static void show(BuildContext context, Map<String, dynamic> member, String groupId) {
    bool isAdmin = member['role'] == 'admin'; // Initial state based on current role

    final TextEditingController nameController = TextEditingController(text: member['name']);
    final TextEditingController contactController = TextEditingController(text: member['contact']);
    final TextEditingController emailController = TextEditingController(text: member['email']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Member'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: contactController,
                    decoration: InputDecoration(labelText: 'Contact'),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                  SwitchListTile(
                    title: Text(isAdmin ? 'Admin' : 'Regular Member'),
                    value: isAdmin,
                    onChanged: (bool value) {
                      setState(() {
                        isAdmin = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                _saveMemberChanges(
                  member['userId'],
                  nameController.text,
                  contactController.text,
                  emailController.text,
                  isAdmin,
                  groupId,
                  context, // Pass the context to close the dialog
                );
              },
            ),
            TextButton(
              child: Text('Disable Account'),
              onPressed: () {
                _confirmDisableAccount(context, member['userId'], groupId); // Confirmation before disabling
              },
            ),
            TextButton(
              child: Text('Delete Account', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _confirmDeleteMember(context, member['userId'], groupId); // Confirmation before deletion
              },
            ),
          ],
        );
      },
    );
  }

  // Confirm disabling account
  static void _confirmDisableAccount(BuildContext context, String userId, String groupId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Disable'),
          content: Text(
            'Disabling this account will prevent the user from logging in and using the app, but their data will remain intact. '
            'You can choose to delete the account later. Are you sure you want to proceed?'
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Disable', style: TextStyle(color: Colors.orange)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the confirmation dialog
                _disableMemberAccount(userId, groupId, context); // Proceed to disable
              },
            ),
          ],
        );
      },
    );
  }

  // Confirm deletion before actually proceeding
  static void _confirmDeleteMember(BuildContext context, String userId, String groupId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text(
            'Deleting this member will permanently remove their account from the system, including all their data. '
            'This action cannot be undone. Are you sure you want to proceed?'
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the confirmation dialog
                _deleteMember(userId, groupId, context); // Proceed to delete
              },
            ),
          ],
        );
      },
    );
  }

  // Save member changes using a Firestore transaction to prevent duplication
  static Future<void> _saveMemberChanges(
    String userId,
    String name,
    String contact,
    String email,
    bool isAdmin,
    String groupId,
    BuildContext context,
  ) async {
    try {
      // Start Firestore transaction to prevent duplication
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Get group document reference
        DocumentReference groupRef = FirebaseFirestore.instance.collection('groups').doc(groupId);

        // Get the current data of the group
        DocumentSnapshot groupSnapshot = await transaction.get(groupRef);

        if (groupSnapshot.exists) {
          // Fetch the current members array
          List<dynamic> members = groupSnapshot.get('members');

          // Find the index of the current user in the members array
          int index = members.indexWhere((member) => member['userId'] == userId);

          if (index >= 0) {
            // Remove the current member from the array (to avoid duplication)
            members.removeAt(index);
          }

          // Update the member's details
          members.add({
            'userId': userId,
            'name': name,
            'contact': contact,
            'email': email,
            'role': isAdmin ? 'admin' : 'member', // Set role to admin or member
          });

          // Update the Firestore group document
          transaction.update(groupRef, {'members': members});
        }

        // Update Firestore `users` collection with new member details
        DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);
        transaction.update(userRef, {
          'name': name,
          'email': email,
          'phone': contact,
          'role': isAdmin ? 'admin' : 'member', // Set role to admin or member
        });
      });

      // Update Firebase Authentication if email has changed
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == userId && currentUser.email != email) {
        await currentUser.updateEmail(email);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Member updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Close dialog after successful update
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating member: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error updating member: $e');
    }
  }

  // Disable member account by setting a "disabled" flag in Firestore
  static Future<void> _disableMemberAccount(String userId, String groupId, BuildContext context) async {
    try {
      // Step 1: Set the disabled field in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'disabled': true, // Mark the user as disabled
        'disabledAt': Timestamp.now(), // Timestamp for when the account was disabled
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account disabled successfully.'),
          backgroundColor: Colors.orange,
        ),
      );

      // Optionally update the group document to mark the member as disabled
      await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([{'userId': userId}]),
      });

      // Update the group to mark the member as disabled in the members array
      await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([{
          'userId': userId,
          'disabled': true,
        }]),
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error disabling account: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error disabling account: $e');
    }
  }

  // Delete member from Firebase Auth, Firestore users collection, and group using transaction
  static Future<void> _deleteMember(String userId, String groupId, BuildContext context) async {
    try {
      // Step 1: Delete the Firebase Authentication user
      User? currentUser = FirebaseAuth.instance.currentUser;

      // If the current user is the one being deleted, delete their Firebase Auth account
      if (currentUser != null && currentUser.uid == userId) {
        await currentUser.delete();
      }

      // Step 2: Delete from Firestore (users collection and group members)
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Get group document reference
        DocumentReference groupRef = FirebaseFirestore.instance.collection('groups').doc(groupId);

        // Get the current data of the group
        DocumentSnapshot groupSnapshot = await transaction.get(groupRef);

        if (groupSnapshot.exists) {
          // Fetch the current members array
          List<dynamic> members = groupSnapshot.get('members');

          // Find the index of the current user in the members array
          int index = members.indexWhere((member) => member['userId'] == userId);

          if (index >= 0) {
            // Remove the member from the array
            members.removeAt(index);
          }

          // Update the Firestore group document
          transaction.update(groupRef, {'members': members});
        }

        // Remove from Firestore users collection
        DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);
        transaction.delete(userRef);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Member deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Close the dialog after deletion
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting member: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error deleting member: $e');
    }
  }
}
