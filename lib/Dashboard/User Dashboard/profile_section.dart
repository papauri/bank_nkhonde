import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For file upload
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileSection extends StatefulWidget {
  final String? profilePictureUrl;

  ProfileSection({this.profilePictureUrl});

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
    profilePictureUrl = widget.profilePictureUrl;
    // If no profile picture exists, fetch it from Firestore on initialization
    if (profilePictureUrl == null) {
      _fetchProfilePicture();
    }
  }

  Future<void> _fetchProfilePicture() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists && userDoc['profilePicture'] != null) {
        setState(() {
          profilePictureUrl = userDoc['profilePicture'];
        });
      }
    } catch (e) {
      print('Error fetching profile picture: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80); // Compressed for quality
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _uploadProfilePicture();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected.')),
      );
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_imageFile != null && currentUserId != null) {
      try {
        // Upload the image to Firebase Storage
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
          SnackBar(content: Text('Failed to upload profile picture. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 40,
            backgroundImage: profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                ? NetworkImage(profilePictureUrl!)
                : null,
            child: profilePictureUrl == null || profilePictureUrl!.isEmpty
                ? Icon(Icons.person, size: 40)
                : null,  // Show default avatar if no DP is available
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Tap to change profile picture',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
