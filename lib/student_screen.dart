import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({Key? key}) : super(key: key);

  @override
  _StudentScreenState createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con imagen
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
                        hintText: "Buscar",
                        prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),

                // 📌 Lista de profesores
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('teachers').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No hay profesores disponibles"));
                      }

                      var teachers = snapshot.data!.docs.where((doc) {
                        var nombre = doc['nombre'].toString().toLowerCase();
                        var materia = doc['materia'].toString().toLowerCase();
                        return nombre.contains(searchQuery) || materia.contains(searchQuery);
                      }).toList();

                      if (teachers.isEmpty) {
                        return const Center(child: Text("No se encontraron resultados"));
                      }

                      return ListView.builder(
                        itemCount: teachers.length,
                        itemBuilder: (context, index) {
                          var teacher = teachers[index];
                          return _buildTeacherCard(
                            teacher['nombre'],
                            teacher['materia'],
                            teacher['precio'],
                            teacher['rating'],
                            teacher['photoUrl'],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Card de profesor
  Widget _buildTeacherCard(String nombre, String materia, int precio, int rating, String photoUrl) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Foto
            CircleAvatar(
              radius: 30,
              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty ? const Icon(Icons.person, size: 40) : null,
            ),
            const SizedBox(width: 12),

            // Datos profesor
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple)),
                  Text(materia, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 5),
                  Text("💲 $precio/h", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Botón reservar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {},
              child: const Text("Reservar", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}


