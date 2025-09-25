import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfesorScreen extends StatefulWidget {
  const ProfesorScreen({super.key});

  @override
  State<ProfesorScreen> createState() => _ProfesorScreenState();
}

class _ProfesorScreenState extends State<ProfesorScreen> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controladores de perfil
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _materiaController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  String? _docId; // id del documento en teachers
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadPerfil();
  }

  // 🔹 Cargar datos del profesor desde Firestore
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
        _precioController.text = doc["precio"].toString(); // 👈 string para input
        _descripcionController.text = doc["descripcion"] ?? "";
      });
    }
  }

  // 🔹 Guardar cambios en Firestore
  Future<void> _guardarCambios() async {
    if (_docId == null) return;

    try {
      await _firestore.collection("teachers").doc(_docId).update({
        "nombre": _nombreController.text,
        "telefono": _telefonoController.text,
        "materia": _materiaController.text,
        "precio": int.tryParse(_precioController.text) ?? 0, // 👈 int seguro
        "descripcion": _descripcionController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil actualizado ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e")),
      );
    }
  }

  // 🔹 Cerrar sesión
  Future<void> _cerrarSesion() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  // 🔹 Widget de pantalla con fondo y contenido centrado
  Widget _buildPlaceholder(String titulo) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            "assets/fondo.png",
            fit: BoxFit.cover,
          ),
        ),
        Center(
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
        ),
      ],
    );
  }

  // 🔹 Pantallas del BottomNavigationBar
  List<Widget> get _screens => [
    _buildPlaceholder("Clases asignadas próximamente..."),
    _buildPlaceholder("Mensajes próximamente..."),
    _buildPlaceholder("Agenda próximamente..."),

    // Perfil
    Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            "assets/fondo.png",
            fit: BoxFit.cover,
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin:
              const EdgeInsets.symmetric(vertical: 30, horizontal: 12),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.purple,
                      child: Icon(Icons.person,
                          size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "Mi Perfil",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Nombre
                    TextField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: "Nombre",
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Teléfono
                    TextField(
                      controller: _telefonoController,
                      decoration: InputDecoration(
                        labelText: "Teléfono",
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Materia
                    TextField(
                      controller: _materiaController,
                      decoration: InputDecoration(
                        labelText: "Materia",
                        prefixIcon: const Icon(Icons.book),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Precio
                    TextField(
                      controller: _precioController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Precio por hora",
                        prefixIcon: const Icon(Icons.monetization_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Descripción
                    TextField(
                      controller: _descripcionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Descripción",
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Botón Guardar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _guardarCambios,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding:
                          const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                          shadowColor: Colors.purpleAccent,
                        ),
                        child: const Text(
                          "Guardar Cambios",
                          style:
                          TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Botón Cerrar Sesión
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _cerrarSesion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding:
                          const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                          shadowColor: Colors.redAccent,
                        ),
                        child: const Text(
                          "Cerrar Sesión",
                          style:
                          TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black26,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Colors.purple,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          iconSize: 30, // 👈 iconos más grandes
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.class_), label: "Clases"),
            BottomNavigationBarItem(icon: Icon(Icons.message), label: "Mensajes"),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month), label: "Agenda"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
          ],
        ),
      ),
    );
  }
}
