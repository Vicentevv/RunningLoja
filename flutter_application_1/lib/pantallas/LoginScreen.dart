import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Definición de colores principales
const Color _kPrimaryColor = Color(0xFF4C7C63);
const Color _kSecondaryColor = Color(0xFFE9F3E5);
const Color _kHintColor = Colors.grey;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // 👇 Controladores para leer email y password
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _isLoading = false;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // FUNCION DE LOGIN REAL
  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        //Si inició sesión correctamente, va a Home
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/HomeScreen');
          _showMessage("Ingreso exitoso");
        }
      } on FirebaseAuthException catch (e) {
        String mensaje = "Error al iniciar sesión";

        if (e.code == 'user-not-found') {
          mensaje = "No existe una cuenta con ese correo";
        } else if (e.code == 'wrong-password') {
          mensaje = "Contraseña incorrecta";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

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
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 20),

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

            const Text(
              '¡Bienvenido de vuelta!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'Inicia sesión para continuar corriendo',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: _kHintColor),
            ),
            const SizedBox(height: 40),

            _buildLoginForm(context),
            const SizedBox(height: 20),

            GestureDetector(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: '¿No tienes cuenta? ',
                  style: const TextStyle(color: _kHintColor, fontSize: 15),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Crear Cuenta',
                      style: const TextStyle(
                        color: _kPrimaryColor,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () =>
                            Navigator.pushNamed(context, '/RegisterScreen'),
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
          children: [
            const Text(
              'Correo electrónico',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildEmailField(),
            const SizedBox(height: 20),

            const Text(
              'Contraseña',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildPasswordField(),
            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {}, // Aquí puedes luego poner recuperar password
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    color: _kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 🔽 BOTÓN LOGIN REAL
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Iniciar sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📌 Email con validación
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      validator: (value) =>
          value != null && value.contains("@") ? null : "Correo inválido",
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: 'tu@email.com',
        hintStyle: const TextStyle(color: _kHintColor),
        prefixIcon: const Icon(Icons.email_outlined, color: _kPrimaryColor),
        filled: true,
        fillColor: _kSecondaryColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // 🔐 Password con validación
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      validator: (value) =>
          value != null && value.length >= 6 ? null : "Mínimo 6 caracteres",
      obscureText: _obscureText,
      decoration: InputDecoration(
        hintText: '••••••••',
        hintStyle: const TextStyle(color: _kHintColor),
        prefixIcon: const Icon(Icons.lock_outline, color: _kPrimaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
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
      ),
    );
  }
}
