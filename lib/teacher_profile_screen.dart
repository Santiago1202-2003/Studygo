import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TeacherProfileScreen extends StatefulWidget {
  final String teacherId;

  const TeacherProfileScreen({Key? key, required this.teacherId})
      : super(key: key);

  @override
  _TeacherProfileScreenState createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isLoading = true;
  Map<String, dynamic>? teacherData;

  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(widget.teacherId)
          .get();

      if (doc.exists) {
        setState(() {
          teacherData = doc.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("❌ Error al cargar el perfil: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => selectedTime = picked);
  }

  Future<void> _reservarClase() async {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor selecciona fecha y hora.")),
      );
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debes iniciar sesión para reservar.")),
        );
        return;
      }

      // Combina fecha y hora en un solo DateTime
      final fechaReserva = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      await FirebaseFirestore.instance.collection("bookings").add({
        "studentId": user.uid,
        "teacherId": widget.teacherId,
        "studentName": user.email ?? "Estudiante",
        "materia": teacherData!["materia"] ?? "Sin materia",
        "fecha": fechaReserva,
        "estado": "pendiente",
        "creadoEn": DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Clase reservada correctamente ✅"),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        selectedDate = null;
        selectedTime = null;
      });
    } catch (e) {
      print("❌ Error al reservar clase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al reservar clase: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (teacherData == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("No se encontró la información del profesor.")),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con la imagen existente
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/fondo.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 50),

                // Ícono de perfil (sin foto)
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.deepPurple.shade100,
                  child: const Icon(Icons.person,
                      size: 70, color: Colors.deepPurple),
                ),
                const SizedBox(height: 16),

                Text(
                  teacherData!['nombre'] ?? 'Profesor sin nombre',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple),
                ),
                const SizedBox(height: 8),
                Text(
                  teacherData!['materia'] ?? 'Materia no especificada',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),

                // 🟣 Cuadro con información del profesor
                Card(
                  color: Colors.white.withOpacity(0.95),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 8,
                  shadowColor: Colors.deepPurple.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("📘 Descripción:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.deepPurple)),
                        Text(teacherData!['descripcion'] ?? "No disponible"),
                        const SizedBox(height: 10),
                        const Text("📄 Hoja de vida:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.deepPurple)),
                        Text(teacherData!['hojaVida'] ?? "No cargada"),
                        const SizedBox(height: 10),
                        const Text("🎓 Diploma:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.deepPurple)),
                        Text(teacherData!['diploma'] ?? "No cargado"),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  "Selecciona fecha y hora:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _selectDate,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple),
                      child: const Text("Fecha"),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _selectTime,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple),
                      child: const Text("Hora"),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                if (selectedDate != null || selectedTime != null)
                  Card(
                    color: Colors.deepPurple.shade50,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Column(
                        children: [
                          if (selectedDate != null)
                            Text(
                              "📅 ${DateFormat('EEEE, dd MMMM yyyy', 'es').format(selectedDate!)}",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          if (selectedTime != null)
                            Text(
                              "🕒 ${selectedTime!.format(context)}",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: _reservarClase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    "Reservar Clase",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
