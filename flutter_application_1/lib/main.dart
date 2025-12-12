import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/firebase_options.dart';

// Pantallas
import 'package:flutter_application_1/pantallas/CommunityScreen.dart';
import 'package:flutter_application_1/pantallas/EventosScreen.dart';
import 'package:flutter_application_1/pantallas/HomeScreen.dart';
import 'package:flutter_application_1/pantallas/LoginScreen.dart';
import 'package:flutter_application_1/pantallas/ProfileScreen.dart';
import 'package:flutter_application_1/pantallas/RegisterScreen.dart';
import 'package:flutter_application_1/pantallas/TrainingScreen.dart';
import 'package:flutter_application_1/pantallas/AdminUserScreen.dart';
import 'package:flutter_application_1/pantallas/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RunLoja',
      theme: ThemeData(
        primaryColor: const Color(0xFF4C7C63),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: const MaterialColor(0xFF4C7C63, {
            50: Color(0xFFE9F3E5),
            100: Color(0xFFC7E0CE),
            200: Color(0xFFA0CBA5),
            300: Color(0xFF78B67C),
            400: Color(0xFF5A9F63),
            500: Color(0xFF4C7C63),
            600: Color(0xFF43705C),
            700: Color(0xFF3B6252),
            800: Color(0xFF335448),
            900: Color(0xFF283D31),
          }),
        ).copyWith(secondary: const Color(0xFFF0983A)),
        useMaterial3: true,
      ),

      // Pantalla inicial (Splash verificará si va a Login o Home)
      home: const Splash(),

      // Rutas globales
      routes: {
        '/LoginScreen': (_) => LoginScreen(),
        '/RegisterScreen': (_) => RegistroScreen(),
        '/HomeScreen': (_) => HomeScreen(),
        '/EventosScreen': (_) => EventosScreen(),
        '/ProfileScreen': (_) => ProfileScreen(),
        '/CommunityScreen': (_) => CommunityScreen(),
        '/TrainingScreen': (_) => EntrenarScreen(),
        '/AdminUserScreen': (_) => AdminUsersScreen(),
      },

      debugShowCheckedModeBanner: false,
    );
  }
}
