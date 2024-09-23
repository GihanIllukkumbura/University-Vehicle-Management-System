import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String senderId;
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    Key? key,
    required this.senderId,
    required this.receiverId,
    required this.receiverName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.receiverName}'),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Chat Information'),
                  content: Text(
                    'Sender ID: ${widget.senderId}\nReceiver ID: ${widget.receiverId}\nReceiver Name: ${widget.receiverName}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(getChatId(widget.senderId, widget.receiverId))
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return MessageBubble(
                    message: data['message'] as String,
                    isSender: data['senderId'] == widget.senderId,
                  );
                }).toList();

                if (messages.isEmpty) {
                  return Center(child: Text('No messages yet'));
                }

                return ListView(
                  reverse: true,
                  children: messages,
                );
              },
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: 'Type your message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    sendMessage(_messageController.text);
                    _messageController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void sendMessage(String message) async {
    final chatId = getChatId(widget.senderId, widget.receiverId);
    final messageDoc = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();
    messageDoc.set({
      'senderId': widget.senderId,
      'receiverId': widget.receiverId,
      'message': message,
      'timestamp': Timestamp.now(),
    });
  }

  String getChatId(String senderId, String receiverId) {
    return senderId.hashCode <= receiverId.hashCode
        ? '$senderId-$receiverId'
        : '$receiverId-$senderId';
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isSender;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isSender,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.0),
      margin: EdgeInsets.only(
        top: 8.0,
        bottom: 8.0,
        left: isSender ? 40.0 : 0.0,
        right: !isSender ? 40.0 : 0.0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: isSender ? Colors.blue[100] : Colors.grey[200],
      ),
      child: Text(message),
    );
  }
}
