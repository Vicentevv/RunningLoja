import 'package:flutter/material.dart';
import 'package:flutter_application_1/pantallas/Bienvenida.dart';
import 'package:flutter_application_1/pantallas/CommunityScreen.dart';
import 'package:flutter_application_1/pantallas/EventosScreen.dart';
import 'package:flutter_application_1/pantallas/HomeScreen.dart';
import 'package:flutter_application_1/pantallas/LoginScreen.dart';
import 'package:flutter_application_1/pantallas/ProfileScreen.dart';
import 'package:flutter_application_1/pantallas/RegisterScreen.dart';
import 'package:flutter_application_1/pantallas/TrainingScreen.dart';

// Asegúrate de que las rutas a tus pantallas sean correctas.
// Si las tienes en la misma carpeta o en 'pantallas/', ajústalas.
import 'package:flutter_application_1/pantallas/splash.dart';
// import 'package:flutter_application_1/pantallas/welcome_screen.dart'; // No se necesita aquí si Splash navega a ella

void main() {
  // Asegura que los widgets estén inicializados antes de correr la app.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ejecuta la aplicación, empezando por el widget principal MyApp.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 1. Título de la Aplicación (se ve en la lista de apps recientes)
      title: 'RunLoja',
      
      // 2. Definición del Tema (colores globales y tipografía)
      theme: ThemeData(
        // Establece el color primario de tu aplicación
        primaryColor: const Color(0xFF4C7C63), // Verde Oscuro
        // Establece el color de acento
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: const MaterialColor(0xFF4C7C63, <int, Color>{
            50: Color(0xFFE9F3E5),
            100: Color(0xFFC7E0CE),
            200: Color(0xFFA0CBA5),
            300: Color(0xFF78B67C),
            400: Color(0xFF5A9F63),
            500: Color(0xFF4C7C63), // El color principal
            600: Color(0xFF43705C),
            700: Color(0xFF3B6252),
            800: Color(0xFF335448),
            900: Color(0xFF283D31),
          }),
        ).copyWith(
          secondary: const Color(0xFFF0983A), // Naranja/Amarillo (para acentos)
        ),
        
        // La fuente Pacifico solo debe aplicarse al título "RunLoja", no a toda la app.
        // Si no defines 'fontFamily' aquí, usará la fuente por defecto (Roboto).
        
        useMaterial3: true,
      ),
      
      // 3. Inicio de la Aplicación
      // La aplicación empieza con la pantalla de carga (Splash).
      home: const Splash(), 
      routes: {
        '/Bienvenida': (_) => WelcomeScreen(),
        '/LoginScreen': (_) => LoginScreen(),
        '/RegisterScreen': (_) => RegistroScreen(), 
        '/HomeScreen': (_) => HomeScreen(),
        '/EventosScreen': (_) => EventosScreen(),
        '/ProfileScreen': (_) => ProfileScreen(),
        '/CommunityScreen': (_) => CommunityScreen(),
        '/TrainingScreen': (_) => EntrenarScreen(),
      },
      
      // Desactiva el banner de debug en la esquina
      debugShowCheckedModeBanner: false,

      
    );
  }
}