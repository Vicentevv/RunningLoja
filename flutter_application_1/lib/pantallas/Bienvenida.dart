import 'package:flutter/material.dart';

// Definición de colores principales
const Color _kPrimaryColor = Color(0xFF4C7C63); // Verde Oscuro del botón
const Color _kAccentColor = Color(0xFFF0983A);  // Naranja/Amarillo (para fondo y acentos)
const Color _kBackgroundColor = Color(0xFFEFDDC9); // Color de fondo si no hay imagen

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos MediaQuery para obtener la altura de la pantalla
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: <Widget>[
         
          // 1. Imagen de Fondo (Fondo de color naranja con un corredor/paisaje)
          Positioned.fill(
            child: Container(
              color: _kBackgroundColor, // Color de respaldo
              child: ColorFiltered( // <-- ¡Añadimos ColorFiltered aquí!
                colorFilter: ColorFilter.mode(
                  _kAccentColor.withOpacity(0.5), // Tono naranja-dorado
                  BlendMode.multiply,
                ),
                child: Image.asset(
                  // **IMPORTANTE:** Reemplaza con la ruta de tu imagen de fondo real.
                  '/running_background.png',
                  fit: BoxFit.cover,
                  // Nota: colorFilter ya NO va aquí en Image.asset
                ),
              ),
            ),
          ),

          // 2. Contenido Superior (Logo y Título)
          Positioned(
            top: screenHeight * 0.1, // Colocado a un 10% del top
            left: 0,
            right: 0,
            child: Column(
              children: <Widget>[
                // Logo (Reutilizando la estructura redondeada)
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: Image(
                      image: const AssetImage('/LogoRunLoja.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Título RunLoja (Fuente Pacifico)
                const Text(
                  'RunLoja',
                  style: TextStyle(
                    fontFamily: 'Pacifico',
                    fontSize: 34,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 5.0,
                        color: Colors.black26,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),

                // Subtítulo
                const Text(
                  'Tu comunidad de running',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // 3. Tarjeta de Bienvenida (La caja blanca inferior)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: screenHeight * 0.65, // Ocupa el 65% inferior de la pantalla
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Título de bienvenida
                  const Text(
                    '¡Bienvenido!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  const Text(
                    'Únete a la comunidad de runners más activa de Loja y descubre una nueva forma de correr',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 4. Secciones de Funcionalidades (Eventos, Comunidad, Entrenar)
                  _buildFeatureIcons(),
                  const SizedBox(height: 40),

                  // 5. Botones de Acción
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Lógica para iniciar sesión
                        Navigator.pushNamed(
                          context, 
                          '/LoginScreen'
                        );
                      },
                      icon: const Icon(Icons.login, size: 24),
                      label: const Text('Iniciar Sesión'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Lógica para crear cuenta
                        Navigator.pushNamed(
                          context, 
                          '/RegisterScreen'
                        );
                      },
                      icon: const Icon(Icons.person_add_alt_1, size: 24),
                      label: const Text('Crear Cuenta Nueva'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: _kPrimaryColor, width: 2),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6. Texto de Términos y Condiciones
                  const Text(
                    'Al continuar, aceptas nuestros términos y condiciones de uso y política de privacidad',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para construir los íconos de las funcionalidades
  Widget _buildFeatureIcons() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        _FeatureColumn(icon: Icons.calendar_today, label: 'Eventos'),
        _FeatureColumn(icon: Icons.group, label: 'Comunidad'),
        _FeatureColumn(icon: Icons.emoji_events, label: 'Entrenar'),
      ],
    );
  }
}

// Widget auxiliar para cada columna de funcionalidad
class _FeatureColumn extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureColumn({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE9F3E5), // Fondo verde muy claro
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 30,
            color: _kPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}