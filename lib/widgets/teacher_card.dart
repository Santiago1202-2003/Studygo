import 'package:flutter/material.dart';
import '../screens/chat_screen.dart';
import '../services/chat_service.dart';

class TeacherCard extends StatelessWidget {
  final String teacherId;
  final String teacherName;
  final String studentId;
  final String studentName;

  const TeacherCard({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.studentId,
    required this.studentName,
  });

  Future<void> _openChat(BuildContext context) async {
    final chatService = ChatService();

    try {
      final chatId = await chatService.createOrGetChat(
        teacherId: teacherId,
        studentId: studentId,
        teacherName: teacherName,
        studentName: studentName,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            teacherId: teacherId,
            studentId: studentId,
            teacherName: teacherName,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al abrir el chat: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(teacherName),
        trailing: IconButton(
          icon: const Icon(Icons.chat, color: Colors.purple),
          onPressed: () => _openChat(context),
        ),
      ),
    );
  }
}
