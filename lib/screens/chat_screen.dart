import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String teacherId;
  final String studentId;
  final String teacherName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.teacherId,
    required this.studentId,
    required this.teacherName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  // 🔹 Enviar mensaje
  Future<void> _sendMessage() async {
    final user = _auth.currentUser;
    if (user == null || _messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      // Guardar mensaje en Firestore
      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'text': messageText,
        'senderId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Actualizar el último mensaje del chat
      await _firestore.collection('chats').doc(widget.chatId).set({
        'lastMessage': messageText,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'teacherId': widget.teacherId,
        'studentId': widget.studentId,
      }, SetOptions(merge: true));

      // Desplazar hacia el final
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al enviar mensaje: $e")),
      );
    }
  }

  // 🔹 Mostrar los mensajes del chat
  Widget _buildMessages() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No hay mensajes aún"));
        }

        final messages = snapshot.data!.docs;
        final currentUser = _auth.currentUser;

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final data = messages[index].data() as Map<String, dynamic>;
            final bool isMe = data['senderId'] == currentUser?.uid;
            final String text = data['text'] ?? '';

            return Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: isMe ? Colors.purple.shade400 : Colors.grey.shade300,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft:
                    isMe ? const Radius.circular(14) : const Radius.circular(0),
                    bottomRight:
                    isMe ? const Radius.circular(0) : const Radius.circular(14),
                  ),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.teacherName),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: const Border(top: BorderSide(color: Colors.grey)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText: "Escribe un mensaje...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.purple),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}