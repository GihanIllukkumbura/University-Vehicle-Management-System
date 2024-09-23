import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatScreen.dart';

class UserList extends StatefulWidget {
  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
  Map<String, int> newMessageCounts =
      {}; // Map to store new message counts for each user

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(223, 255, 186, 1.0),
                Color.fromRGBO(234, 185, 185, 1.0)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        color: Color(0xFFA2C776), // Light background color
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            // Sort the documents to put "Admin" first
            var docs = snapshot.data!.docs;
            docs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              if (aData['username'] == 'Admin') return -1;
              if (bData['username'] == 'Admin') return 1;
              return 0;
            });

            return ListView(
              children: docs
                  .where(
                      (doc) => doc.id != currentUserUid) // Exclude current user
                  .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final imageUrl = data['image_url'] as String?;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 4.0, horizontal: 8.0),
                  child: Card(
                    color: Color(0xFFFFFFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 27,
                        backgroundImage: imageUrl != null
                            ? NetworkImage(imageUrl)
                            : null, // Use null if no image URL
                        child: imageUrl == null
                            ? Icon(Icons.account_circle,
                                size: 40.0,
                                color: Colors
                                    .grey) // Display default icon if no image URL
                            : null, // Don't show anything if there's an image URL
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${data['username']}',
                            style: TextStyle(
                              fontWeight: (newMessageCounts[doc.id] ?? 0) > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                          if ((newMessageCounts[doc.id] ?? 0) > 0)
                            CircleAvatar(
                              backgroundColor: Colors.red,
                              radius: 10,
                              child: Text(
                                '${newMessageCounts[doc.id]}',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12.0),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        data['status'] ?? '', // Assuming there's a status field
                        style: TextStyle(color: Colors.grey),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              senderId: currentUserUid,
                              receiverId: doc.id, // Pass the receiver's ID here
                              receiverName: data['username'] ?? 'No Username',
                            ),
                          ),
                        );
                        setState(() {
                          newMessageCounts[doc.id] =
                              0; // Reset new message count when navigating to chat
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Listen to new messages and update newMessageCounts accordingly
    FirebaseFirestore.instance
        .collection('chats')
        .where('receiverId', isEqualTo: currentUserUid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((querySnapshot) {
      querySnapshot.docChanges.forEach((change) {
        if (change.type == DocumentChangeType.added) {
          setState(() {
            final senderId = change.doc['senderId'] as String;
            newMessageCounts.update(senderId, (value) => (value ?? 0) + 1,
                ifAbsent: () => 1);
          });
        }
      });
    });
  }
}
