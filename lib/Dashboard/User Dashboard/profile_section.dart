import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileSection extends StatefulWidget {
  @override
  _ProfileSectionState createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String? profilePictureUrl;
  File? _imageFile;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchProfilePicture();
  }

  Future<void> _fetchProfilePicture() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (userDoc.exists && userDoc.data() != null) {
      setState(() {
        profilePictureUrl = userDoc['profilePicture'];
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _uploadProfilePicture();
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_imageFile != null) {
      String imageUrl = 'https://example.com/dummy-url'; // Replace with actual upload URL
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({'profilePicture': imageUrl});

      setState(() {
        profilePictureUrl = imageUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 50,
              backgroundImage:
                  profilePictureUrl != null ? NetworkImage(profilePictureUrl!) : null,
              child: profilePictureUrl == null ? Icon(Icons.person, size: 50) : null,
            ),
          ),
          SizedBox(height: 10),
          Text('Welcome to your dashboard', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
