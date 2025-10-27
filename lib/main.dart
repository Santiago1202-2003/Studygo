import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ Import necesario
import 'firebase_options.dart';

import 'login_screen.dart';
import 'register_screen.dart';
import 'inicio_screen.dart'; // 👈 la pantalla con logo y botones
import 'home_screen.dart';  // 👈 pantalla principal con menú inferior

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 📅 Inicializa los formatos de fecha para español (Colombia)
  await initializeDateFormatting('es_CO', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StudyGo',
      home: const InicioScreen(), // 👈 primera pantalla
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(), // 👈 principal después de login
      },
    );
  }
}

