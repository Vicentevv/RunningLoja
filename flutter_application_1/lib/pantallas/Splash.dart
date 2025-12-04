import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

// IMPORTA tus pantallas:
import 'package:flutter_application_1/pantallas/HomeScreen.dart';
import 'package:flutter_application_1/pantallas/LoginScreen.dart';

// ====================================================================
// CLASE AUXILIAR DE ANIMACIÓN: _StaggeredDotCurve (sin cambios)
// ====================================================================
class _StaggeredDotCurve extends Curve {
  final double begin;
  final double end;

  const _StaggeredDotCurve({required this.begin, required this.end});

  @override
  double transform(double t) {
    if (t < begin || t > end) {
      return 0.0;
    }
    double normalizedT = (t - begin) / (end - begin);
    if (normalizedT <= 0.5) {
      return normalizedT * 2.0;
    } else {
      return 2.0 - (normalizedT * 2.0);
    }
  }
}
// ====================================================================

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  final Color _backgroundColor = const Color(0xFF38978E);

  late AnimationController _controller;
  late Animation<double> _dot1Animation;
  late Animation<double> _dot2Animation;
  late Animation<double> _dot3Animation;

  @override
  void initState() {
    super.initState();

    // Animaciones (NO se toca)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _dot1Animation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const _StaggeredDotCurve(begin: 0.0, end: 0.5),
      ),
    );
    _dot2Animation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const _StaggeredDotCurve(begin: 0.25, end: 0.75),
      ),
    );
    _dot3Animation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const _StaggeredDotCurve(begin: 0.5, end: 1.0),
      ),
    );

    _checkUserSession();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🚀 NUEVA LÓGICA: Decide a dónde ir después del splash
  Future<void> _checkUserSession() async {
    await Future.delayed(const Duration(seconds: 6)); // Tu tiempo del splash

    User? user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user != null) {
      // Usuario ya inició sesión -> ir directo a HOME
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      // No hay usuario -> ir a LOGIN (o bienvenida si quieres)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  // Widget auxiliar para crear un punto animado (NO TOCAR)
  Widget _buildAnimatedDot(Animation<double> animation) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Logo/Icono
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: ClipOval(
                child: Image(
                  image: const AssetImage('assets/LogoRunLoja.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Título
            const Text(
              'RunLoja',
              style: TextStyle(
                fontFamily: 'Pacifico',
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Subtítulo
            const Text(
              'Tu comunidad de running',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 40),

            // Indicador animado
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnimatedDot(_dot1Animation),
                const SizedBox(width: 8),
                _buildAnimatedDot(_dot2Animation),
                const SizedBox(width: 8),
                _buildAnimatedDot(_dot3Animation),
              ],
            ),
            const SizedBox(height: 40),

            // Texto de carga
            const Text(
              'Cargando tu experiencia de running...',
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
