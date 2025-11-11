import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Definición de colores principales
const Color _kPrimaryColor = Color(0xFF4C7C63); // Verde Oscuro
const Color _kSecondaryColor = Color(0xFFE9F3E5); // Fondo verde claro
const Color _kHintColor = Colors.grey;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext) {
    return Scaffold(
      // El color de fondo es blanco, pero podemos poner un color ligero para simular el fondo de la imagen
      backgroundColor: Colors.white,

      // La AppBar simple con el botón de retroceso
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                // Lógica para regresar a la pantalla anterior (WelcomeScreen)
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 20),

            // 1. Icono de Runner en el círculo verde
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: _kPrimaryColor,
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: const Icon(
                Icons.directions_run_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),

            // 2. Título principal
            const Text(
              '¡Bienvenido de vuelta!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50), // Color oscuro para contraste
              ),
            ),
            const SizedBox(height: 8),

            // 3. Subtítulo
            const Text(
              'Inicia sesión para continuar corriendo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: _kHintColor,
              ),
            ),
            const SizedBox(height: 40),

            // 4. Formulario y Tarjeta Blanca
            _buildLoginForm(context),

            const SizedBox(height: 20),

            // 7. ¿No tienes cuenta?
            GestureDetector(
              onTap: () {
                // Lógica para navegar a la pantalla de registro
                // Dejamos este onTap vacío a propósito, ya que el recognizer
                // de abajo maneja el tap en el texto específico.
                // Opcionalmente, puedes hacer que todo el texto navegue:
                // Navigator.pushNamed(context, '/RegisterScreen');
              },
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: '¿No tienes cuenta? ', // Hay un espacio al final
                  style: const TextStyle(color: _kHintColor, fontSize: 15),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'correr aquí',
                      style: const TextStyle(
                        color: _kPrimaryColor,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          // Navegar a la pantalla de registro
                          Navigator.pushNamed(context, '/RegisterScreen');
                        },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Campo Correo Electrónico
            const Text(
              'Correo electrónico',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              hint: 'tu@email.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // Campo Contraseña
            const Text(
              'Contraseña',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            _buildPasswordField(),
            const SizedBox(height: 10),

            // 5. ¿Olvidaste tu?
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  // Lógica para recuperar contraseña
                },
                child: const Text(
                  '¿Olvidaste tu?',
                  style: TextStyle(
                    color: _kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Botón Principal: Iniciar Sesión
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Lógica para iniciar sesión
                    Navigator.pushNamed(context, '/HomeScreen');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Iniciar sesión'),
              ),
            ),
            const SizedBox(height: 20),

            // Separador "o continúa con"
            _buildDividerWithText('o continúa con'),
            const SizedBox(height: 20),

            // 6. Botón de Google
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Lógica de inicio de sesión con Google
                },
                icon: Image.asset(
                  '/google_logo.webp', // Asegúrate que esta ruta sea correcta
                  height: 24.0,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.login, color: Colors.redAccent); // Fallback
                  },
                ),
                label: const Text('Continuar con Google'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey.shade300, width: 1),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para campos de texto genéricos
  Widget _buildTextField({
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kHintColor),
        prefixIcon: Icon(icon, color: _kPrimaryColor),
        filled: true,
        fillColor: _kSecondaryColor, // Fondo verde claro
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  // Widget para el campo de contraseña
  Widget _buildPasswordField() {
    return TextFormField(
      obscureText: _obscureText,
      decoration: InputDecoration(
        hintText: '••••••••',
        hintStyle: const TextStyle(color: _kHintColor),
        prefixIcon: const Icon(Icons.lock_outline, color: _kPrimaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: _kPrimaryColor,
          ),
          onPressed: _togglePasswordVisibility,
        ),
        filled: true,
        fillColor: _kSecondaryColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  // Widget para el separador con texto
  Widget _buildDividerWithText(String text) {
    return Row(
      children: <Widget>[
        const Expanded(child: Divider(color: _kHintColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Text(
            text,
            style: const TextStyle(color: _kHintColor),
          ),
        ),
        const Expanded(child: Divider(color: _kHintColor, thickness: 1)),
      ],
    );
  }
}