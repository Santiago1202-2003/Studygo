import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherService {
  final CollectionReference teachersCollection =
  FirebaseFirestore.instance.collection('teachers');

  Future<void> createTeacherProfile({
    required String uid,
    required String name,
    required String subject,
    required String bio,
    required String photoUrl,
  }) async {
    await teachersCollection.doc(uid).set({
      'name': name,
      'subject': subject,
      'bio': bio,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> teacherProfileExists(String uid) async {
    final doc = await teachersCollection.doc(uid).get();
    return doc.exists;
  }
}
