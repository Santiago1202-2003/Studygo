import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/chat_screen.dart';

class ProfesorScreen extends StatefulWidget {
  const ProfesorScreen({super.key});

  @override
  State<ProfesorScreen> createState() => _ProfesorScreenState();
}

class _ProfesorScreenState extends State<ProfesorScreen> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _materiaController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  String? _docId;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
    _loadPerfil();
  }

  Future<void> _loadPerfil() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final query = await _firestore
        .collection("teachers")
        .where("uid", isEqualTo: user.uid)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      setState(() {
        _docId = doc.id;
        _nombreController.text = doc["nombre"] ?? "";
        _telefonoController.text = doc["telefono"] ?? "";
        _materiaController.text = doc["materia"] ?? "";
        _precioController.text = doc["precio"].toString();
        _descripcionController.text = doc["descripcion"] ?? "";
      });
    } else {
      await _firestore.collection("teachers").add({
        "uid": user.uid,
        "nombre": "",
        "telefono": "",
        "materia": "",
        "precio": 0,
        "descripcion": "",
      });
      _loadPerfil();
    }
  }

  Future<void> _guardarCambios() async {
    if (_docId == null) return;
    try {
      await _firestore.collection("teachers").doc(_docId).update({
        "nombre": _nombreController.text.trim(),
        "telefono": _telefonoController.text.trim(),
        "materia": _materiaController.text.trim(),
        "precio": int.tryParse(_precioController.text.trim()) ?? 0,
        "descripcion": _descripcionController.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil actualizado")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e")),
      );
    }
  }

  Future<void> _cerrarSesion() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  Future<void> _actualizarEstado(String bookingId, String estado) async {
    try {
      final bookingDoc =
      await _firestore.collection("bookings").doc(bookingId).get();

      if (!bookingDoc.exists) return;

      final data = bookingDoc.data()!;
      final studentId = data["studentId"];
      final studentName = data["studentName"];
      final materia = data["materia"] ?? "clase";

      await _firestore.collection("bookings").doc(bookingId).update({
        "estado": estado,
        "respuestaProfesor": DateTime.now(),
      });

      if (estado == "aceptada") {
        await _firestore.collection("agenda_profesor").add({
          "teacherId": _auth.currentUser?.uid,
          "studentName": studentName,
          "materia": materia,
          "fecha": data["fecha"],
          "hora": data["hora"],
          "bookingId": bookingId,
        });

        // 🟣 CAMBIO: crear chat con campos teacherId / studentId
        final currentUser = _auth.currentUser;
        if (currentUser != null && studentId != null) {
          final chatQuery = await _firestore
              .collection("chats")
              .where("teacherId", isEqualTo: currentUser.uid)
              .where("studentId", isEqualTo: studentId)
              .get();

          if (chatQuery.docs.isEmpty) {
            await _firestore.collection("chats").add({
              "teacherId": currentUser.uid,
              "studentId": studentId,
              "teacherName": _nombreController.text.trim(),
              "studentName": studentName,
              "users": [currentUser.uid, studentId],
              "lastMessage": "Nuevo chat con $studentName",
              "lastTimestamp": DateTime.now(),
            });
          }
        }
      }

      if (studentId != null) {
        await _firestore.collection("notifications").add({
          "studentId": studentId,
          "teacherId": _auth.currentUser?.uid,
          "mensaje": estado == "aceptada"
              ? "Tu profesor ha aceptado la clase de $materia."
              : "Tu profesor ha rechazado la clase de $materia.",
          "fecha": DateTime.now(),
          "leido": false,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              estado == "aceptada"
                  ? "Clase aceptada correctamente ✅"
                  : "Clase rechazada ❌",
            ),
            backgroundColor:
            estado == "aceptada" ? Colors.green : Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al actualizar estado: $e")),
      );
    }
  }

  Widget _clasesAsignadas() {
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text("No autenticado"));

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection("bookings")
          .where("teacherId", isEqualTo: user.uid)
          .orderBy("fecha", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No tienes reservas aún"));
        }

        final bookings = snapshot.data!.docs;
        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            var data = bookings[index].data() as Map<String, dynamic>;
            String estado = data["estado"];
            DateTime fecha = (data["fecha"] as Timestamp).toDate();
            String fechaStr =
            DateFormat("EEEE d 'de' MMMM, hh:mm a", 'es').format(fecha);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.purple,
                          child:
                          Icon(Icons.person, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            data["studentName"] ?? "Estudiante desconocido",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          estado == "pendiente"
                              ? Icons.hourglass_empty
                              : estado == "aceptada"
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: estado == "pendiente"
                              ? Colors.orange
                              : estado == "aceptada"
                              ? Colors.green
                              : Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text("Materia: ${data["materia"]}",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 6),
                    Text("Fecha: $fechaStr",
                        style: const TextStyle(
                            fontSize: 15, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 10),
                    if (estado == "pendiente")
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check, color: Colors.white),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            onPressed: () => _actualizarEstado(
                                bookings[index].id, "aceptada"),
                            label: const Text("Aceptar",
                                style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            onPressed: () => _actualizarEstado(
                                bookings[index].id, "rechazada"),
                            label: const Text("Rechazar",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🟣 CHAT: Lista de chats activos (profesor)
  Widget _chatsProfesor() {
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text("No autenticado"));

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .where('teacherId', isEqualTo: user.uid)
          .orderBy('lastTimestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Aún no tienes conversaciones"));
        }

        final chats = snapshot.data!.docs;
        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            var data = chats[index].data() as Map<String, dynamic>;
            final studentId = data['studentId'] ?? '';
            final studentName = data['studentName'] ?? 'Estudiante';

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(studentName),
              subtitle: Text(data['lastMessage'] ?? ''),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId: chats[index].id,
                      teacherId: user.uid,
                      studentId: studentId,
                      teacherName: _nombreController.text.trim(),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _agendaProfesor() {
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text("No autenticado"));

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection("agenda_profesor")
          .where("teacherId", isEqualTo: user.uid)
          .orderBy("fecha", descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("No tienes clases aceptadas en tu agenda"));
        }

        final clases = snapshot.data!.docs;
        return ListView.builder(
          itemCount: clases.length,
          itemBuilder: (context, index) {
            var data = clases[index].data() as Map<String, dynamic>;
            DateTime fecha = (data["fecha"] as Timestamp).toDate();
            String fechaStr =
            DateFormat("EEEE d 'de' MMMM, hh:mm a", 'es').format(fecha);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.purple.shade50,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const Icon(Icons.book_online, color: Colors.purple),
                title: Text(
                  data["materia"] ?? "Materia desconocida",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                subtitle: Text(
                  "Estudiante: ${data["studentName"]}\nFecha: $fechaStr",
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> get _screens => [
    _clasesAsignadas(),
    _chatsProfesor(),
    _agendaProfesor(),
    _perfilScreen(),
  ];

  Widget _perfilScreen() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Center(
      child: Card(
        elevation: 8,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(vertical: 30, horizontal: 12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.purple,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text("Mi Perfil",
                  style:
                  TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              _input("Nombre", _nombreController, Icons.person),
              _input("Teléfono", _telefonoController, Icons.phone),
              _input("Materia", _materiaController, Icons.book),
              _input("Precio por hora", _precioController,
                  Icons.monetization_on,
                  number: true),
              _input("Descripción", _descripcionController,
                  Icons.description,
                  multiline: true),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _guardarCambios,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 18)),
                child: const Text("Guardar Cambios",
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _cerrarSesion,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 18)),
                child: const Text("Cerrar Sesión",
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _input(String label, TextEditingController controller, IconData icon,
      {bool number = false, bool multiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        maxLines: multiline ? 3 : 1,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        iconSize: 30,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.class_), label: "Clases"),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Mensajes"),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: "Agenda"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}
