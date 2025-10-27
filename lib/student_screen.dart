import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'teacher_profile_screen.dart';
import 'screens/chat_screen.dart'; // 👈 Importa tu ChatScreen

class StudentScreen extends StatefulWidget {
  const StudentScreen({Key? key}) : super(key: key);

  @override
  _StudentScreenState createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  String searchQuery = "";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _explorarProfesores(), // Tu pantalla original
          _chatsActivos(), // Nueva pantalla de chat
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: "Profesores",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: "Mensajes",
          ),
        ],
      ),
    );
  }

  // 🔹 Pantalla 1: Explorar profesores (tu código original)
  Widget _explorarProfesores() {
    return Stack(
      children: [
        // 🖼️ Fondo
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/fondo.png"),
              fit: BoxFit.cover,
            ),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              // 🔎 Buscador
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.deepPurple, width: 2),
                    color: Colors.white.withOpacity(0.9),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: "Buscar profesor o materia",
                      prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

              // 📘 Lista de profesores
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('teachers')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("No hay profesores disponibles"),
                      );
                    }

                    var teachers = snapshot.data!.docs.where((doc) {
                      var nombre = doc['nombre'].toString().toLowerCase();
                      var materia = doc['materia'].toString().toLowerCase();
                      return nombre.contains(searchQuery) ||
                          materia.contains(searchQuery);
                    }).toList();

                    if (teachers.isEmpty) {
                      return const Center(
                        child: Text("No se encontraron resultados"),
                      );
                    }

                    return ListView.builder(
                      itemCount: teachers.length,
                      itemBuilder: (context, index) {
                        var teacher =
                        teachers[index].data() as Map<String, dynamic>;
                        teacher['uid'] = teachers[index].id;
                        return _buildTeacherCard(teacher);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🧑‍🏫 Tarjeta del profesor (sin cambios)
  Widget _buildTeacherCard(Map<String, dynamic> teacher) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.deepPurple.shade100,
              child: const Icon(Icons.person, size: 40, color: Colors.deepPurple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher["nombre"] ?? "Profesor",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.deepPurple,
                    ),
                  ),
                  Text(
                    teacher["materia"] ?? "",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "💲 ${teacher["precio"] ?? 0}/h",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 🔘 Botón para ir al perfil del profesor
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeacherProfileScreen(
                      teacherId: teacher['uid'],
                    ),
                  ),
                );
              },
              child: const Text(
                "Reservar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Pantalla 2: Chats activos del estudiante
  Widget _chatsActivos() {
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text("No autenticado"));

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Mis chats con profesores",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("bookings")
                  .where("studentId", isEqualTo: user.uid)
                  .where("estado", isEqualTo: "aceptada")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No tienes chats activos aún"),
                  );
                }

                final clases = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: clases.length,
                  itemBuilder: (context, index) {
                    var data = clases[index].data() as Map<String, dynamic>;
                    String teacherId = data["teacherId"];
                    String teacherName = data["teacherName"] ?? "Profesor";
                    String chatId = data["bookingId"] ?? clases[index].id;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          teacherName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple),
                        ),
                        subtitle: Text("Materia: ${data["materia"] ?? ""}"),
                        trailing:
                        const Icon(Icons.chat_bubble, color: Colors.purple),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatId: chatId,
                                teacherId: teacherId,
                                studentId: user.uid,
                                teacherName: teacherName,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



