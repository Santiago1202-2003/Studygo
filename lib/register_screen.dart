import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profesor_screen.dart';
import 'student_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController experienceLinkController = TextEditingController();
  final TextEditingController cvLinkController = TextEditingController();

  String role = "estudiante";
  bool acceptTerms = false;

  // Registro en Firebase
  Future<void> registerUser() async {
    if (role == "profesor" && !acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Debes aceptar los términos y condiciones")),
      );
      return;
    }

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Completa todos los campos obligatorios")),
      );
      return;
    }

    try {
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      if (role == "estudiante") {
        // ✅ Guardar solo en "users"
        await FirebaseFirestore.instance.collection("users").doc(uid).set({
          "uid": uid,
          "email": emailController.text.trim(),
          "role": role,
          "createdAt": FieldValue.serverTimestamp(),
        });
      } else if (role == "profesor") {
        // ✅ Guardar solo en "teachers"
        await FirebaseFirestore.instance.collection("teachers").doc(uid).set({
          "uid": uid,
          "nombre": nameController.text.trim(),
          "telefono": phoneController.text.trim(),
          "email": emailController.text.trim(),
          "materia": "", // editable después
          "descripcion": "",
          "precio": 0,
          "rating": 0,
          "photoUrl": "",
          "experienceLink": experienceLinkController.text.trim(),
          "cvLink": cvLinkController.text.trim(),
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Usuario registrado con éxito")),
      );

      // 🚀 Redirección automática después de guardar
      await redirectUser(uid);

      // Limpiar campos
      emailController.clear();
      passwordController.clear();
      nameController.clear();
      phoneController.clear();
      experienceLinkController.clear();
      cvLinkController.clear();
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      if (e.code == 'email-already-in-use') {
        errorMsg = "⚠️ Este correo ya está registrado.";
      } else if (e.code == 'weak-password') {
        errorMsg = "⚠️ La contraseña es demasiado débil.";
      } else if (e.code == 'invalid-email') {
        errorMsg = "⚠️ Correo inválido.";
      } else {
        errorMsg = "Error: ${e.message}";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    }
  }

  // 🚀 Redirección según la colección donde esté el usuario
  Future<void> redirectUser(String uid) async {
    final teacherDoc =
    await FirebaseFirestore.instance.collection("teachers").doc(uid).get();

    if (teacherDoc.exists) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfesorScreen()),
      );
      return;
    }

    final studentDoc =
    await FirebaseFirestore.instance.collection("users").doc(uid).get();

    if (studentDoc.exists) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StudentScreen()),
      );
      return;
    }

    // Si no está en ninguna colección
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("⚠️ No se encontró el perfil del usuario.")),
    );
  }

  // Input con diseño
  Widget buildTextField(
      TextEditingController controller,
      String hint, {
        bool obscure = false,
        TextInputType type = TextInputType.text,
      }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/fondo.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/logo.png", height: 100),
                const SizedBox(height: 20),

                // Botones Profesor / Estudiante
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          role == "profesor" ? Colors.deepPurple : Colors.white,
                          foregroundColor:
                          role == "profesor" ? Colors.white : Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            role = "profesor";
                          });
                        },
                        child: const Text("Profesor"),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: role == "estudiante"
                              ? Colors.deepPurple
                              : Colors.white,
                          foregroundColor:
                          role == "estudiante" ? Colors.white : Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            role = "estudiante";
                          });
                        },
                        child: const Text("Estudiante"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (role == "profesor") ...[
                  buildTextField(nameController, "Nombre completo"),
                  const SizedBox(height: 12),
                  buildTextField(phoneController, "Número de teléfono",
                      type: TextInputType.phone),
                  const SizedBox(height: 12),
                ],

                buildTextField(emailController, "Correo electrónico",
                    type: TextInputType.emailAddress),
                const SizedBox(height: 12),

                buildTextField(passwordController, "Contraseña", obscure: true),
                const SizedBox(height: 12),

                if (role == "profesor") ...[
                  buildTextField(experienceLinkController,
                      "Link de experiencia laboral (Google Drive, Dropbox, etc.)"),
                  const SizedBox(height: 12),
                  buildTextField(
                      cvLinkController, "Link de hoja de vida (PDF en la nube)"),
                  const SizedBox(height: 12),
                ],

                // Botón principal
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: registerUser,
                    child: const Text("Registrarse",
                        style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 15),

                // ✅ Términos y condiciones debajo del botón
                if (role == "profesor") ...[
                  Row(
                    children: [
                      Checkbox(
                        value: acceptTerms,
                        onChanged: (val) {
                          setState(() {
                            acceptTerms = val ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          "Acepto términos y condiciones",
                          style: TextStyle(color: Colors.deepPurple),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Recuerda que esta app solo será activada para el Valle del Cauca",
                    style: TextStyle(fontSize: 12, color: Colors.deepPurple),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],

                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text(
                    "¿Ya tienes cuenta? Iniciar sesión",
                    style: TextStyle(
                      color: Colors.deepPurple,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
