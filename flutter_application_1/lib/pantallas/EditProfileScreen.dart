import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // IMPORTANTE: Agregado para respaldo de UID

// Ajusta estos imports a tu estructura real si es necesario
import 'package:flutter_application_1/pantallas/ProfileScreen.dart'
    hide kPrimaryTextColor, kPrimaryGreen, kSecondaryTextColor;

const kPrimaryColor = Color(
  0xFF4DB6AC,
); // Color primario (ajustar si tienes constantes globales)

class EditProfileScreen extends StatefulWidget {
  final Map<String, String> currentUserData;

  const EditProfileScreen({super.key, required this.currentUserData});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoadingData = true; // Para mostrar carga inicial
  bool _isSaving = false; // Para mostrar carga al guardar

  // --- Controladores de Texto ---
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _alturaController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _objetivoController = TextEditingController();

  // --- Variables para Selectores ---
  DateTime? _selectedBirthDate;
  String? _selectedGender;
  String? _selectedCategory;
  String? _selectedExperience;

  // Imagen codificada
  String? avatarBase64;

  @override
  void initState() {
    super.initState();
    // Cargamos los datos directamente de Firebase para asegurar que estén actualizados
    _loadUserData();
  }

  // 🔄 FUNCIÓN CRÍTICA: Cargar datos frescos de Firebase
  Future<void> _loadUserData() async {
    // 1. Intentamos obtener el UID del mapa que pasaste
    String? uid = widget.currentUserData['uid'];

    // 2. RESPALDO: Si vino vacío o nulo, lo sacamos de la sesión actual de Auth
    if (uid == null || uid.isEmpty) {
      uid = FirebaseAuth.instance.currentUser?.uid;
      print("Aviso: UID no recibido en argumentos, usando UID de Auth: $uid");
    }

    if (uid == null || uid.isEmpty) {
      print("ERROR CRÍTICO: No se pudo encontrar un UID válido.");
      setState(() => _isLoadingData = false);
      _populateFromMap(widget.currentUserData);
      return;
    }

    try {
      print("Consultando Firestore para usuario: $uid"); // DEBUG
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        print(
          "Datos encontrados: ${doc.data()}",
        ); // DEBUG: Verás tus datos en consola
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Asignar datos a controladores (convirtiendo tipos si es necesario)
        _nombreController.text = data['fullName'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _descripcionController.text = data['role'] ?? '';

        // Manejo de números (Height/Weight pueden venir como int o double)
        _alturaController.text = (data['height'] ?? 0).toString();
        _pesoController.text = (data['weight'] ?? 0).toString();

        _objetivoController.text = data['currentGoal'] ?? '';

        // Imagen
        avatarBase64 = data['avatarBase64'];

        // Fecha (Manejo robusto: puede venir como String ISO o Timestamp)
        if (data['birthDate'] != null) {
          if (data['birthDate'] is String) {
            _selectedBirthDate = DateTime.tryParse(data['birthDate']);
          } else if (data['birthDate'] is Timestamp) {
            _selectedBirthDate = (data['birthDate'] as Timestamp).toDate();
          }
        }

        // Selectores (Deben coincidir EXACTAMENTE con las opciones del Dropdown)
        _selectedGender = data['gender'];
        _selectedCategory = data['category'];
        _selectedExperience = data['experience'];

        // Forzar actualización de la UI
        if (mounted) setState(() {});
      } else {
        print("El documento del usuario no existe en Firestore.");
        _populateFromMap(widget.currentUserData);
      }
    } catch (e) {
      print("Error cargando perfil desde Firestore: $e");
      _populateFromMap(widget.currentUserData);
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  void _populateFromMap(Map<String, String> map) {
    _nombreController.text = map['fullName'] ?? '';
    _emailController.text = map['email'] ?? '';
    _phoneController.text = map['phone'] ?? '';
    _descripcionController.text = map['role'] ?? '';
    _alturaController.text = map['height'] ?? '';
    _pesoController.text = map['weight'] ?? '';
    _objetivoController.text = map['currentGoal'] ?? '';

    if (map['birthDate'] != null && map['birthDate']!.isNotEmpty) {
      _selectedBirthDate = DateTime.tryParse(map['birthDate']!);
    }

    _selectedGender = map['gender'];
    _selectedCategory = map['category'];
    _selectedExperience = map['experience'];
    avatarBase64 = map['avatarBase64'];
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descripcionController.dispose();
    _alturaController.dispose();
    _pesoController.dispose();
    _objetivoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await File(picked.path).readAsBytes();
    setState(() {
      avatarBase64 = base64Encode(bytes);
    });
  }

  Future<void> _pickDate() async {
    DateTime initial = _selectedBirthDate ?? DateTime(2000);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryColor,
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

  // --- Guardado DIRECTO en Firebase ---
  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    // 1. Usar lógica de respaldo también al guardar
    String? uid = widget.currentUserData['uid'];
    if (uid == null || uid.isEmpty) {
      uid = FirebaseAuth.instance.currentUser?.uid;
    }

    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se encontró el ID de usuario')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Parsear números
      double heightVal = double.tryParse(_alturaController.text) ?? 0.0;
      double weightVal = double.tryParse(_pesoController.text) ?? 0.0;

      // Fecha a ISO String
      String birthDateStr = _selectedBirthDate?.toIso8601String() ?? "";

      // Actualizar en Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fullName': _nombreController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _descripcionController.text.trim(),
        'height': heightVal,
        'weight': weightVal,
        'currentGoal': _objetivoController.text.trim(),
        'avatarBase64': avatarBase64 ?? "",
        'birthDate': birthDateStr, // Guardamos como String ISO
        'gender': _selectedGender ?? "",
        'category': _selectedCategory ?? "",
        'experience': _selectedExperience ?? "",
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
        Navigator.pop(context, true); // Retornamos true para indicar éxito
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Color de fondo claro
      appBar: AppBar(
        title: const Text(
          'Editar Perfil',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(color: kPrimaryColor),
                )
              : TextButton(
                  onPressed: _isLoadingData
                      ? null
                      : _onSave, // Desactivar si cargando
                  child: const Text(
                    'Guardar',
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
        ],
      ),

      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : AbsorbPointer(
              absorbing: _isSaving,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- AVATAR ---
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: kPrimaryColor.withOpacity(0.8),
                            backgroundImage:
                                (avatarBase64 != null &&
                                    avatarBase64!.isNotEmpty)
                                ? MemoryImage(base64Decode(avatarBase64!))
                                : null,
                            child: Stack(
                              children: [
                                if (avatarBase64 == null ||
                                    avatarBase64!.isEmpty)
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
                                      color: kPrimaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4.0),
                                      child: Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // --- INFORMACIÓN PERSONAL ---
                      Text(
                        'Información personal',
                        style: _sectionTitleStyle(context),
                      ),
                      const SizedBox(height: 16),

                      _buildTextFormField(
                        controller: _nombreController,
                        label: 'Nombre completo',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextFormField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              readOnly: true,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextFormField(
                              controller: _phoneController,
                              label: 'Teléfono',
                              icon: Icons.phone_android_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildDatePickerField(
                              label: "Nacimiento",
                              selectedDate: _selectedBirthDate,
                              onTap: _pickDate,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField(
                              label: "Género",
                              value: _selectedGender,
                              items: ["Masculino", "Femenino", "Otro"],
                              icon: Icons.people_outline,
                              onChanged: (val) =>
                                  setState(() => _selectedGender = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildTextFormField(
                        controller: _descripcionController,
                        label: 'Descripción (Role)',
                        icon: Icons.info_outline,
                      ),

                      const SizedBox(height: 24),

                      // --- DATOS FÍSICOS ---
                      Text('Datos físicos', style: _sectionTitleStyle(context)),
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

                      // --- INFORMACIÓN DE RUNNING ---
                      Text(
                        'Información de running',
                        style: _sectionTitleStyle(context),
                      ),
                      const SizedBox(height: 16),

                      _buildDropdownField(
                        label: "Categoría",
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
                      const SizedBox(height: 16),

                      _buildDropdownField(
                        label: "Nivel de experiencia",
                        value: _selectedExperience,
                        items: [
                          "Principiante",
                          "Intermedio",
                          "Avanzado",
                          "Elite",
                        ],
                        icon: Icons.star_outline,
                        onChanged: (val) =>
                            setState(() => _selectedExperience = val),
                      ),

                      const SizedBox(height: 24),

                      // --- OBJETIVOS ---
                      Text('Mis objetivos', style: _sectionTitleStyle(context)),
                      const SizedBox(height: 16),

                      _buildTextFormField(
                        controller: _objetivoController,
                        label: 'Objetivo principal',
                        icon: Icons.flag_outlined,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // --- ESTILOS Y HELPERS ---

  TextStyle _sectionTitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
  }

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
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: kPrimaryColor),
        suffixText: suffixText,
        suffixStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
        ),
      ),
      validator: (value) {
        if (label.contains("Nombre") || label.contains("Email")) {
          if (value == null || value.isEmpty) return 'Requerido';
        }
        return null;
      },
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: kPrimaryColor),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectedDate != null)
                  Text(
                    label,
                    style: const TextStyle(color: Colors.black54, fontSize: 10),
                  ),
                Text(
                  selectedDate == null
                      ? label
                      : DateFormat('dd/MM/yyyy').format(selectedDate),
                  style: TextStyle(
                    color: selectedDate == null
                        ? Colors.black54
                        : Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, color: kPrimaryColor),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: Colors.black54)),
            ],
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Icon(icon, color: kPrimaryColor),
                  const SizedBox(width: 12),
                  Text(item, style: const TextStyle(color: Colors.black87)),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
