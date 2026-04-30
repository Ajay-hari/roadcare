import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String requestId;

  const ChatPage({super.key, required this.requestId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  final TextEditingController msg = TextEditingController();
  final uid = FirebaseAuth.instance.currentUser!.uid;

  // SEND MESSAGE
  Future<void> sendMessage() async {

    if (msg.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection("requests")
        .doc(widget.requestId)
        .collection("messages")
        .add({
      "text": msg.text.trim(),
      "senderId": uid,
      "timestamp": FieldValue.serverTimestamp(),
    });

    msg.clear();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[50],

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Chat",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Column(
        children: [

          // MESSAGE LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("requests")
                  .doc(widget.requestId)
                  .collection("messages")
                  .orderBy("timestamp")
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {

                    final data = messages[index];
                    final isMe = data["senderId"] == uid;

                    return _chatBubble(
                      message: data["text"],
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),

          //  INPUT BOX
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: msg,
                    decoration: const InputDecoration(
                      hintText: "Type message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                CircleAvatar(
                  backgroundColor: Colors.amber,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: sendMessage,
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  // CHAT BUBBLE
  Widget _chatBubble({required String message, required bool isMe}) {

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: isMe ? Colors.amber : Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(message),
      ),
    );
  }
}