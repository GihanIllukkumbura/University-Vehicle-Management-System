import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebasefluttter/widgets/user_image_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileEditPage extends StatefulWidget {
  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late TextEditingController _usernameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _nicNumberController;
  late TextEditingController _universityIdController;
  late TextEditingController _licenseIdController;
  File? _selectedImage;
  bool _isLogin = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _nicNumberController = TextEditingController();
    _universityIdController = TextEditingController();
    _licenseIdController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneNumberController.dispose();
    _nicNumberController.dispose();
    _universityIdController.dispose();
    _licenseIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              Map<String, dynamic>? userData =
              snapshot.data!.data() as Map<String, dynamic>?;

              _usernameController.text = userData?['username'] ?? '';
              _phoneNumberController.text = userData?['phone_number'] ?? '';
              _nicNumberController.text = userData?['nic_number'] ?? '';
              _universityIdController.text = userData?['university_id'] ?? '';
              _licenseIdController.text = userData?['license_id'] ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isLogin)
                          UserImagePicker(
                            onPickImage: (File pickedImage) {
                              setState(() {
                                _selectedImage = pickedImage;
                              });
                            },
                          ),
                        if (_selectedImage != null)
                          Image.file(
                            _selectedImage!,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                      ],
                    ),
                  ),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'User Name',
                    ),
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: _phoneNumberController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                    ),
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: _nicNumberController,
                    decoration: InputDecoration(
                      labelText: 'NIC Number',
                    ),
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: _universityIdController,
                    decoration: InputDecoration(
                      labelText: 'University ID',
                    ),
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: _licenseIdController,
                    decoration: InputDecoration(
                      labelText: 'License ID',
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Update user data in Firestore
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .update({
                          'username': _usernameController.text,
                          'phone_number': _phoneNumberController.text,
                          'nic_number': _nicNumberController.text,
                          'university_id': _universityIdController.text,
                          'license_id': _licenseIdController.text,
                        });

                        // Upload image to Firebase Storage if a new image is selected
                        if (_selectedImage != null) {
                          final storageRef = FirebaseStorage.instance
                              .ref()
                              .child('user_images')
                              .child('${FirebaseAuth.instance.currentUser!.uid}.jpg');

                          await storageRef.putFile(_selectedImage!);
                          final imageUrl = await storageRef.getDownloadURL();

                          // Save image URL in Firestore
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .update({
                            'image_url': imageUrl,
                          });
                        }

                        // Navigate back to the previous screen
                        Navigator.pop(context);
                      },
                      child: Text('Save Changes'),
                    ),
                  ),

                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
