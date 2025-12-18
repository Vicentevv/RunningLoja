import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // NECESARIO para fechas
import 'package:flutter_application_1/modelos/UserModel.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({Key? key}) : super(key: key);

  @override
  _RegistroScreenState createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  // 📌 Controladores de Texto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController =
      TextEditingController(); // NUEVO
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // 📌 Variables de Estado para Selectores (NUEVOS)
  DateTime? _selectedBirthDate;
  String? _selectedGender;
  String? _selectedCategory;
  String? _selectedExperience;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // 📅 Selector de Fecha
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4DB6AC), // Color primario
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  // 🔥 Crear usuario en Firebase
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage("Las contraseñas no coinciden");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 👉 1. Crear el usuario con Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final uid = userCredential.user!.uid;

      // 2. Guardar en Firestore con todos los campos nuevos
      final userModel = UserModel(
        uid: uid,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        createdAt: DateTime.now(),
        totalDistance: 0,
        totalRuns: 0,
        averagePace: "0:00",
        streakDays: 0,
        currentGoal: "Sin objetivo",
        myEventIds: [],
        height: 0,
        weight: 0,
        role: "runner",
        avatarBase64: '',

        // --- CAMPOS NUEVOS ---
        phone: _phoneController.text.trim(),
        birthDate: _selectedBirthDate ?? DateTime(2000, 1, 1),
        gender: _selectedGender ?? "No especificado",
        category: _selectedCategory ?? "Abierta",
        experience: _selectedExperience ?? "Principiante",
      );

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .set(userModel.toJson());

      _showMessage("Cuenta creada correctamente");

      Navigator.pushReplacementNamed(context, '/HomeScreen');
    } catch (e) {
      _showMessage("Error: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF4DB6AC);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- HEADER ---
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.person_add_outlined,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Únete a RunLoja',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completa tu perfil para comenzar.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // 📌 FORMULARIO
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 5,
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nombre completo',
                          hint: 'Tu nombre completo',
                          icon: Icons.person_outline,
                          validator: (value) =>
                              value!.isEmpty ? 'Ingresa un nombre' : null,
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          controller: _emailController,
                          label: 'Correo electrónico',
                          hint: 'tu@email.com',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                              value!.contains('@') ? null : 'Correo inválido',
                        ),
                        const SizedBox(height: 20),

                        // --- CAMPO CELULAR (NUEVO) ---
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Celular',
                          hint: '0987654321',
                          icon: Icons.phone_android_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) =>
                              value!.isEmpty ? 'Ingresa tu celular' : null,
                        ),
                        const SizedBox(height: 20),

                        // --- FECHA Y GÉNERO (NUEVO) ---
                        Row(
                          children: [
                            Expanded(
                              child: _buildDatePicker(
                                label: 'Nacimiento',
                                icon: Icons.calendar_today_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown(
                                label: 'Género',
                                value: _selectedGender,
                                items: ['Masculino', 'Femenino', 'Otro'],
                                icon: Icons.people_outline,
                                onChanged: (val) =>
                                    setState(() => _selectedGender = val),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // --- CATEGORÍA Y EXPERIENCIA (NUEVO) ---
                        _buildDropdown(
                          label: 'Categoría',
                          value: _selectedCategory,
                          items: [
                            "Juvenil (18-25)",
                            "Abierta (26-35 años)",
                            "Master (36-45)",
                            "Veteranos (46+)",
                          ],
                          icon: Icons.category_outlined,
                          onChanged: (val) =>
                              setState(() => _selectedCategory = val),
                        ),
                        const SizedBox(height: 20),

                        _buildDropdown(
                          label: 'Nivel de Experiencia',
                          value: _selectedExperience,
                          items: [
                            "Principiante",
                            "Intermedio",
                            "Avanzado",
                            "Elite",
                          ],
                          icon: Icons.star_border,
                          onChanged: (val) =>
                              setState(() => _selectedExperience = val),
                        ),
                        const SizedBox(height: 20),

                        _buildPasswordField(
                          controller: _passwordController,
                          label: 'Contraseña',
                          hint: '••••••••',
                          obscureText: _obscurePassword,
                          onToggleVisibility: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          validator: (v) =>
                              v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                        ),
                        const SizedBox(height: 20),

                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: 'Confirmar',
                          hint: '••••••••',
                          obscureText: _obscureConfirmPassword,
                          onToggleVisibility: () {
                            setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            );
                          },
                          validator: (v) =>
                              v!.isEmpty ? 'Confirma tu contraseña' : null,
                        ),
                        const SizedBox(height: 32),

                        // 📌 BOTÓN REGISTRAR
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Crear cuenta',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ... Resto del login social y footer igual que antes ...
                  const SizedBox(height: 32),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      children: [
                        const TextSpan(text: '¿Ya tienes cuenta? '),
                        TextSpan(
                          text: 'Inicia sesión aquí',
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(context, '/LoginScreen');
                            },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 📌 Helpers

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({required String label, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Text(
                  _selectedBirthDate == null
                      ? "Seleccionar"
                      : DateFormat('dd/MM/yyyy').format(_selectedBirthDate!),
                  style: TextStyle(
                    color: _selectedBirthDate == null
                        ? Colors.grey[400]
                        : Colors.black87,
                    fontSize: 14, // Ajuste de fuente para espacio
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : null,
              isExpanded: true,
              hint: Row(
                children: [
                  Icon(icon, color: Colors.grey[500], size: 20),
                  const SizedBox(width: 2),
                  Text(
                    "Seleccionar",
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[500]),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey[500],
              ),
              onPressed: onToggleVisibility,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
          ),
        ),
      ],
    );
  }
}
