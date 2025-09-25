import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/teacher_service.dart';

class TeacherProfileSetup extends StatefulWidget {
  const TeacherProfileSetup({super.key});

  @override
  State<TeacherProfileSetup> createState() => _TeacherProfileSetupState();
}

class _TeacherProfileSetupState extends State<TeacherProfileSetup> {
  final _formKey = GlobalKey<FormState>();
  final _teacherService = TeacherService();

  String name = '';
  String subject = '';
  String bio = '';
  String photoUrl = ''; // luego puedes poner picker de imágenes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear perfil de profesor")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "Nombre"),
                onChanged: (val) => setState(() => name = val),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Materia"),
                onChanged: (val) => setState(() => subject = val),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Biografía"),
                onChanged: (val) => setState(() => bio = val),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                child: const Text("Guardar perfil"),
                onPressed: () async {
                  final uid = FirebaseAuth.instance.currentUser!.uid;

                  await _teacherService.createTeacherProfile(
                    uid: uid,
                    name: name,
                    subject: subject,
                    bio: bio,
                    photoUrl: photoUrl,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Perfil creado con éxito")),
                  );

                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
