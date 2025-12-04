import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({Key? key}) : super(key: key);

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  // Controladores
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController requisitosController = TextEditingController();
  final TextEditingController incluyeController = TextEditingController();
  final TextEditingController distanciaController = TextEditingController();
  final TextEditingController maxParticipantesController =
      TextEditingController();
  final TextEditingController organizadorController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  // Dropdowns
  String? selectedTipo;
  String? selectedCategoria;

  final List<String> tipos = [
    "Carrera",
    "Taller",
    "Caminata",
    "Entrenamiento",
    "Campaña",
    "Charla",
  ];

  final List<String> categorias = [
    "Maratón",
    "5K",
    "10K",
    "Trail",
    "Educativo",
    "Salud",
  ];

  // Imagen
  File? selectedImage;
  String? imageBase64;

  final ImagePicker picker = ImagePicker();

  // ----------------------------------------------------------
  //               FUNCIONES PARA IMAGEN
  // ----------------------------------------------------------

  Future<void> pickImage() async {
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);

    if (img != null) {
      final file = File(img.path);
      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);

      setState(() {
        selectedImage = file;
        imageBase64 = base64;
      });
    }
  }

  // ----------------------------------------------------------
  //                GUARDAR EVENTO
  // ----------------------------------------------------------

  Future<void> saveEvent() async {
    if (nameController.text.isEmpty ||
        selectedTipo == null ||
        selectedCategoria == null ||
        selectedDate == null ||
        selectedTime == null ||
        imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Completa todos los campos obligatorios, incluida la imagen",
          ),
        ),
      );
      return;
    }

    final date = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    await FirebaseFirestore.instance.collection("eventos").add({
      "nombre": nameController.text.trim(),
      "tipo": selectedTipo,
      "categoria": selectedCategoria,
      "fecha": date.toIso8601String(),
      "ubicacion": locationController.text.trim(),
      "descripcion": descriptionController.text.trim(),
      "requisitos": requisitosController.text.trim(),
      "incluye": incluyeController.text.trim(),
      "distancia": distanciaController.text.trim(),
      "maxParticipantes": maxParticipantesController.text.trim(),
      "organizador": organizadorController.text.trim(),
      "email": emailController.text.trim(),
      "telefono": telefonoController.text.trim(),

      // Imagen Base64
      "imagenBase64": imageBase64,

      "inscritos": 0,
    });

    Navigator.pop(context);
  }

  // ----------------------------------------------------------
  //                    FECHA Y HORA
  // ----------------------------------------------------------

  Future<void> pickDate() async {
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );

    if (result != null) {
      setState(() => selectedDate = result);
    }
  }

  Future<void> pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (result != null) {
      setState(() => selectedTime = result);
    }
  }

  // ----------------------------------------------------------
  //                       UI
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            _buildFormContainer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF3A7D6E),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          const Text(
            "Crear evento",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Organiza tu propio evento de running",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContainer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),

          _cardSection(
            title: "Información básica *",
            children: [
              _input(
                "Nombre del evento",
                "Ej: Ruta Nocturna UTPL",
                nameController,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _dropdown(
                      "Tipo",
                      tipos,
                      selectedTipo,
                      (v) => setState(() => selectedTipo = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dropdown(
                      "Categoría",
                      categorias,
                      selectedCategoria,
                      (v) => setState(() => selectedCategoria = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _datePicker()),
                  const SizedBox(width: 10),
                  Expanded(child: _timePicker()),
                ],
              ),
              const SizedBox(height: 10),
              _input(
                "Ubicación",
                "Ej: Parque Central de Loja",
                locationController,
              ),
            ],
          ),

          const SizedBox(height: 20),

          _cardSection(
            title: "Detalles del evento",
            children: [
              _textArea(
                "Descripción",
                "Describe el evento...",
                descriptionController,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _input(
                      "Distancia (km)",
                      "Ej: 5",
                      distanciaController,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _input(
                      "Max. participantes",
                      "Ej: 150",
                      maxParticipantesController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _textArea(
                "Requisitos",
                "Ej: Ser mayor de 15 años…",
                requisitosController,
              ),
              const SizedBox(height: 10),
              _textArea("Incluye", "Ej: Camiseta, medalla…", incluyeController),
            ],
          ),

          const SizedBox(height: 20),

          _cardSection(
            title: "Datos del organizador *",
            children: [
              _input(
                "Nombre/Organización",
                "Ej: Running Loja Club",
                organizadorController,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _input(
                      "Email",
                      "Ej: contacto@runningloja.com",
                      emailController,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _input(
                      "Teléfono",
                      "Ej: 0991234567",
                      telefonoController,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _imagePickerSection(),

          const SizedBox(height: 30),
          _submitButton(),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  //                    PICKER DE IMAGEN
  // ----------------------------------------------------------

  Widget _imagePickerSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: pickImage,
          child: Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF3A7D6E),
                width: 2,
                style: BorderStyle.solid,
              ),
              image: selectedImage != null
                  ? DecorationImage(
                      image: FileImage(selectedImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: selectedImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        size: 60,
                        color: Color(0xFF3A7D6E),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Tap para seleccionar imagen",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3A7D6E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "JPG, PNG (máx. 5MB)",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  )
                : Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedImage = null;
                              imageBase64 = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          selectedImage != null
              ? "✓ Imagen seleccionada"
              : "Foto del evento (obligatoria)",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selectedImage != null
                ? const Color(0xFF27AE60)
                : Colors.black54,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // WIDGETS REUTILIZABLES
  // ----------------------------------------------------------

  Widget _input(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black26, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black45, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _textArea(
    String label,
    String hint,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black26, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black45, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdown(
    String label,
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _datePicker() {
    return GestureDetector(
      onTap: pickDate,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 8),
            Text(
              selectedDate == null
                  ? "Fecha"
                  : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
            ),
          ],
        ),
      ),
    );
  }

  Widget _timePicker() {
    return GestureDetector(
      onTap: pickTime,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time),
            const SizedBox(width: 8),
            Text(
              selectedTime == null
                  ? "Hora"
                  : "${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}",
            ),
          ],
        ),
      ),
    );
  }

  Widget _submitButton() {
    return ElevatedButton(
      onPressed: saveEvent,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3A7D6E),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        "Crear evento",
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget _cardSection({required String title, required List<Widget> children}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3A7D6E),
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
