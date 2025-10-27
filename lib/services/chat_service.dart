import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crear o recuperar chat entre profesor y estudiante
  Future<String> createOrGetChat({
    required String teacherId,
    required String studentId,
    required String teacherName,
    required String studentName,
  }) async {
    try {
      // 1️⃣ Buscar si ya existe el chat
      final query = await _firestore
          .collection('chats')
          .where('teacherId', isEqualTo: teacherId)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.id;
      }

      // 2️⃣ Crear nuevo chat
      final newChat = await _firestore.collection('chats').add({
        'teacherId': teacherId,
        'studentId': studentId,
        'teacherName': teacherName,
        'studentName': studentName,
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
      });

      return newChat.id;
    } catch (e) {
      throw Exception("Error al crear chat: $e");
    }
  }
}
