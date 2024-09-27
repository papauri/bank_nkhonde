import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MyGroupsTab extends StatefulWidget {
  final String currentUserId;

  MyGroupsTab({required this.currentUserId});

  @override
  _MyGroupsTabState createState() => _MyGroupsTabState();
}

class _MyGroupsTabState extends State<MyGroupsTab> {
  List<int> expandedTiles = [];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('groups').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final groups = snapshot.data!.docs.where((group) {
          final members = group['members'] as List<dynamic>;
          return members.any((member) => member['userId'] == widget.currentUserId);
        }).toList();

        if (groups.isEmpty) {
          return Center(child: Text('You are not part of any groups.'));
        }

        return ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final groupName = group['groupName'];
            final members = group['members'] as List<dynamic>;

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ExpansionTile(
                key: PageStorageKey<int>(index),
                onExpansionChanged: (expanded) {
                  setState(() {
                    if (expanded) {
                      expandedTiles.clear();
                      expandedTiles.add(index);
                    } else {
                      expandedTiles.remove(index);
                    }
                  });
                },
                initiallyExpanded: expandedTiles.contains(index),
                title: Text(
                  groupName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Members:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 10),
                        _buildMembersList(members),
                      ],
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

  // Fetch Firebase Storage URL if not already available
  Future<String> _getProfilePictureUrl(String? profilePictureField, String userId) async {
    if (profilePictureField != null && profilePictureField.isNotEmpty) {
      return profilePictureField; // If the URL is already stored in Firestore
    } else {
      // If not, fetch from Firebase Storage
      try {
        Reference storageRef = FirebaseStorage.instance.ref().child('profilePictures/$userId.jpg');
        String url = await storageRef.getDownloadURL();
        return url; // Return the download URL
      } catch (e) {
        print('Error fetching image from Firebase Storage: $e');
        return ''; // Return empty if there's an issue
      }
    }
  }

  // Build the list of members with profile pictures
  Widget _buildMembersList(List<dynamic> members) {
    return Column(
      children: members.map((member) {
        final memberName = member['name'];
        final memberProfilePicture = member['profilePicture']; // Field in Firestore
        final memberId = member['userId']; // The user ID is assumed to be stored

        return FutureBuilder<String>(
          future: _getProfilePictureUrl(memberProfilePicture, memberId),  // Get the picture URL
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == '') {
              // If no image, return a default icon
              return ListTile(
                leading: CircleAvatar(
                  child: Icon(Icons.person, size: 30),
                ),
                title: Text(memberName),
              );
            } else {
              // Return the NetworkImage if the URL is valid
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(snapshot.data!), // Load the profile picture from Firebase Storage
                ),
                title: Text(memberName),
              );
            }
          },
        );
      }).toList(),
    );
  }
}
