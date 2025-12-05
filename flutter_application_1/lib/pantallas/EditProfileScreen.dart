import 'dart:convert'; // NUEVO
import 'dart:io'; // NUEVO
import 'package:image_picker/image_picker.dart'; // NUEVO

import 'package:flutter/material.dart';
import 'package:flutter_application_1/pantallas/CommunityScreen.dart';
import 'package:flutter_application_1/pantallas/ProfileScreen.dart'
    hide kPrimaryTextColor, kPrimaryGreen, kSecondaryTextColor;

class EditProfileScreen extends StatefulWidget {
  final Map<String, String> currentUserData;

  const EditProfileScreen({super.key, required this.currentUserData});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _descripcionController;
  late TextEditingController _alturaController;
  late TextEditingController _pesoController;
  late TextEditingController _objetivoController;

  // NUEVO → imagen codificada
  String? avatarBase64;

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(
      text: widget.currentUserData['nombre'],
    );
    _emailController = TextEditingController(
      text: widget.currentUserData['email'],
    );
    _descripcionController = TextEditingController(
      text: widget.currentUserData['descripcion'],
    );
    _alturaController = TextEditingController(
      text: widget.currentUserData['altura'],
    );
    _pesoController = TextEditingController(
      text: widget.currentUserData['peso'],
    );
    _objetivoController = TextEditingController(
      text: widget.currentUserData['objetivo'],
    );

    // Cargar si ya había un avatar guardado
    avatarBase64 = widget.currentUserData['avatarBase64'];
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _descripcionController.dispose();
    _alturaController.dispose();
    _pesoController.dispose();
    _objetivoController.dispose();
    super.dispose();
  }

  // NUEVO → seleccionar imagen y convertir a base64
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final bytes = await File(picked.path).readAsBytes();

    setState(() {
      avatarBase64 = base64Encode(bytes);
    });
  }

  /// Guarda el formulario y regresa a la pantalla anterior
  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        'nombre': _nombreController.text,
        'email': _emailController.text,
        'descripcion': _descripcionController.text,
        'altura': _alturaController.text,
        'peso': _pesoController.text,
        'objetivo': _objetivoController.text,
        'avatarBase64': avatarBase64 ?? "",
      };

      Navigator.pop(context, updatedData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightGrayBackground,
      appBar: AppBar(
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            color: kPrimaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kPrimaryTextColor),
        actions: [
          TextButton(
            onPressed: _onSave,
            child: const Text(
              'Guardar',
              style: TextStyle(
                color: kPrimaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),

      /// 🔥 Mantengo TODO tu diseño EXACTO
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage, // NUEVO
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: kPrimaryGreen.withOpacity(0.8),

                    // Si hay base64, se muestra
                    backgroundImage:
                        (avatarBase64 != null && avatarBase64!.isNotEmpty)
                        ? MemoryImage(base64Decode(avatarBase64!))
                        : null,

                    child: Stack(
                      children: [
                        if (avatarBase64 == null || avatarBase64!.isEmpty)
                          const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),

                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: kPrimaryGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              _buildTextFormField(
                controller: _nombreController,
                label: 'Nombre completo',
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _emailController,
                label: 'Correo electrónico',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                readOnly: true,
              ),

              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _descripcionController,
                label: 'Descripción (Role)',
                icon: Icons.info_outline,
              ),

              const SizedBox(height: 24),

              Text(
                'Información física',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField(
                      controller: _alturaController,
                      label: 'Altura',
                      icon: Icons.height,
                      suffixText: 'cm',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextFormField(
                      controller: _pesoController,
                      label: 'Peso',
                      icon: Icons.monitor_weight_outlined,
                      suffixText: 'kg',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Text(
                'Mis objetivos',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _objetivoController,
                label: 'Objetivo principal',
                icon: Icons.flag_outlined,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget helper original (sin cambios)
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? suffixText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kSecondaryTextColor),
        prefixIcon: Icon(icon, color: kPrimaryGreen),
        suffixText: suffixText,
        suffixStyle: const TextStyle(color: kSecondaryTextColor),
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : Colors.white,
      ),
      validator: (value) => (value == null || value.isEmpty)
          ? 'Este campo no puede estar vacío'
          : null,
    );
  }
}
