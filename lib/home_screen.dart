import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView( // 👈 Esto evita el overflow
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Logo GitHub
                Center(
                  child: Column(
                    children: const [
                      Icon(Icons.code, size: 100, color: Colors.black),
                      SizedBox(height: 10),
                      Text(
                        "GitHub",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Nombre app
                const Text(
                  "StudyGo!",
                  style: TextStyle(
                    fontSize: 26,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // Descripción
                const Text(
                  "Conecta con profesores calificados y recibe\n"
                      "clases personalizadas en cualquier materia.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),

                const SizedBox(height: 40),

                // Botón Iniciar sesión
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Iniciar sesión"),
                  ),
                ),

                const SizedBox(height: 16),

                // Botón Registrarse
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Registrarse"),
                  ),
                ),

                const SizedBox(height: 20),

                // Texto link
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "¿Ya tienes cuenta? Iniciar sesión",
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                ),

                const SizedBox(height: 40),

                // Logo Google centrado
                Center(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.network(
                      "https://upload.wikimedia.org/wikipedia/commons/2/2f/Google_2015_logo.svg",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
