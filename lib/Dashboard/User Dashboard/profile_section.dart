import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';  // For file upload

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

  // Fetch profile picture URL from Firestore
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

  // Pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80); // Compressed for quality
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _uploadProfilePicture();
    }
  }

  // Upload profile picture to Firebase Storage and update Firestore
  Future<void> _uploadProfilePicture() async {
    if (_imageFile != null) {
      try {
        // Uploading the image to Firebase Storage
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('profilePictures')
            .child('$currentUserId.jpg');

        UploadTask uploadTask = storageRef.putFile(_imageFile!);
        await uploadTask;

        // Get the download URL of the uploaded image
        String imageUrl = await storageRef.getDownloadURL();

        // Update the user's profile picture URL in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({'profilePicture': imageUrl});

        setState(() {
          profilePictureUrl = imageUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile picture updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload profile picture. Please try again.')),
        );
      }
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
              radius: 50,  // Instagram-like circular display
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
