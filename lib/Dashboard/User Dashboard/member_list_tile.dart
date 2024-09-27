import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MemberListTile extends StatelessWidget {
  final String name;
  final String? profilePictureUrl;
  final String memberId;

  MemberListTile({
    required this.name,
    required this.profilePictureUrl,
    required this.memberId,
  });

  Future<String> _getProfilePictureUrl() async {
    if (profilePictureUrl != null && profilePictureUrl!.isNotEmpty) {
      return profilePictureUrl!; // Use the existing URL from Firestore
    } else {
      // Fetch from Firebase Storage if profilePictureUrl is not available
      try {
        Reference storageRef = FirebaseStorage.instance.ref().child('profilePictures/$memberId.jpg');
        String downloadUrl = await storageRef.getDownloadURL();
        return downloadUrl;
      } catch (e) {
        print('Error fetching image from Firebase Storage: $e');
        return ''; // Return empty if there's an issue
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getProfilePictureUrl(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Default avatar if no profile picture is found
          return ListTile(
            leading: CircleAvatar(
              child: Icon(Icons.person, size: 30),
            ),
            title: Text(name),
          );
        } else {
          // Display the profile picture from the fetched URL
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(snapshot.data!),
            ),
            title: Text(name),
          );
        }
      },
    );
  }
}
