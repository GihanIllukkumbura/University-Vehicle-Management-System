import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';


class DialPadScreen extends StatefulWidget {
  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<DialPadScreen> {
  final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
  Map<String, int> newMessageCounts = {}; // Map to store new message counts for each user

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call List'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs
                .where((doc) => doc.id != currentUserUid) // Exclude current user
                .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final imageUrl = data['image_url'] as String?;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: imageUrl != null
                      ? NetworkImage(imageUrl)
                      : null, // Use null if no image URL
                  child: imageUrl == null
                      ? Icon(Icons.account_circle, size: 40.0) // Display default icon if no image URL
                      : null, // Don't show anything if there's an image URL
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${data['username']}',
                      style: TextStyle(
                        fontWeight: (newMessageCounts[doc.id] ?? 0) > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.phone),
                      onPressed: () {
                        _loadDialPad(data['phone_number'] ?? '');
                      },
                    ),

                  ],
                ),
                subtitle: Text(data['phone_number'] ?? ''), // Phone number at the bottom
              );

            }).toList(),
          );
        },
      ),
    );
  }
  void _loadDialPad(String phoneNumber) async {
    if (await Permission.phone.request().isGranted) {
      String formattedPhoneNumber =  phoneNumber.replaceAll(RegExp(r'\s+\b|\b\s'), '');
      String url = 'tel:$formattedPhoneNumber';
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        // Handle error: Could not launch phone dialer
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch phone dialer. You might need a default phone app or check the app\'s permissions.'),
          ),
        );
      }
    } else {
      // Handle case when permission is not granted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone permission is required to make calls.'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Listen to new messages and update newMessageCounts accordingly
    // FirebaseFirestore.instance
    //     .collection('chats')
    //     .where('receiverId', isEqualTo: currentUserUid)
    //     .where('isRead', isEqualTo: false)
    //     .snapshots()
    //     .listen((querySnapshot) {
    //   // querySnapshot.docChanges.forEach((change) {
    //   //   // if (change.type == DocumentChangeType.added) {
    //   //   //   setState(() {
    //   //   //     final senderId = change.doc['senderId'] as String;
    //   //   //     newMessageCounts.update(senderId, (value) => (value ?? 0) + 1, ifAbsent: () => 1);
    //   //   //   });
    //   //   // }
    //   // });
    // });
  }
}
