import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/pantallas/CreateEventScreen.dart';
import 'package:flutter_application_1/pantallas/EventDetailScreen.dart';
import 'dart:convert';

// --- Colores reutilizados ---
const Color kPrimaryGreen = Color(0xFF3A7D6E);
const Color kLightGreenBackground = Color(0xFFF0F5F3);
const Color kCardBackgroundColor = Colors.white;
const Color kPrimaryTextColor = Color(0xFF333333);
const Color kSecondaryTextColor = Color(0xFF666666);

class EventInfo {
  final String id;
  final String imageUrl;
  final String imagenBase64;
  final String categoria;
  final String tipo;
  final String nombre;
  final String fecha;
  final String ubicacion;
  final int inscritos;
  final String organizador;
  final String descripcion;
  final String distancia;
  final String maxParticipantes;
  final String email;
  final String telefono;
  final String incluye;
  final String requisitos;

  EventInfo({
    required this.id,
    required this.imageUrl,
    required this.imagenBase64,
    required this.categoria,
    required this.tipo,
    required this.nombre,
    required this.fecha,
    required this.ubicacion,
    required this.inscritos,
    required this.organizador,
    required this.descripcion,
    required this.distancia,
    required this.maxParticipantes,
    required this.email,
    required this.telefono,
    required this.incluye,
    required this.requisitos,
  });

  factory EventInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Manejo seguro de los campos numéricos y de texto
    int parseInscritos() {
      final value = data['inscritos'];
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return EventInfo(
      id: doc.id,
      imageUrl: data['imageUrl'] as String? ?? 'assets/default_event.jpg',
      imagenBase64: data['imagenBase64'] as String? ?? '',
      categoria: data['categoria'] as String? ?? 'Sin categoría',
      tipo: data['tipo'] as String? ?? 'Sin tipo',
      nombre: data['nombre'] as String? ?? 'Sin nombre',
      fecha: data['fecha'] as String? ?? '',
      ubicacion: data['ubicacion'] as String? ?? 'Sin ubicación',
      inscritos: parseInscritos(),
      organizador: data['organizador'] as String? ?? '',
      descripcion: data['descripcion'] as String? ?? '',
      distancia: data['distancia'] as String? ?? '0',
      maxParticipantes: data['maxParticipantes'] as String? ?? '0',
      email: data['email'] as String? ?? '',
      telefono: data['telefono'] as String? ?? '',
      incluye: data['incluye'] as String? ?? '',
      requisitos: data['requisitos'] as String? ?? '',
    );
  }
}

class EventosScreen extends StatefulWidget {
  const EventosScreen({Key? key}) : super(key: key);

  @override
  _EventosScreenState createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  int _selectedToggle = 0;
  int _selectedIndex = 1;

  Stream<List<EventInfo>> _streamEvents() {
    return FirebaseFirestore.instance
        .collection('eventos')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => EventInfo.fromFirestore(doc)).toList(),
        );
  }

  void _onNavBarTap(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/HomeScreen');
        break;
      case 1:
        Navigator.pushNamed(context, '/EventosScreen');
        break;
      case 2:
        Navigator.pushNamed(context, '/ProfileScreen');
        break;
      case 3:
        Navigator.pushNamed(context, '/CommunityScreen');
        break;
      case 4:
        Navigator.pushNamed(context, '/TrainingScreen');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightGreenBackground,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<EventInfo>>(
              stream: _streamEvents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Error al cargar eventos"));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "No hay eventos aún",
                      style: TextStyle(
                        fontSize: 18,
                        color: kSecondaryTextColor,
                      ),
                    ),
                  );
                }

                final events = snapshot.data!;
                final userId = FirebaseAuth.instance.currentUser?.uid;

                final filtered = _selectedToggle == 0
                    ? events
                    : events.where((e) => e.organizador == userId).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildEventCard(filtered[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ---------------- UI ----------------

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
      decoration: const BoxDecoration(
        color: kPrimaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Eventos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 30),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateEventScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildToggle(),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _toggleItem(0, 'Todos los eventos'),
          _toggleItem(1, 'Mis eventos'),
        ],
      ),
    );
  }

  Widget _toggleItem(int index, String label) {
    final selected = _selectedToggle == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedToggle = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? kPrimaryGreen : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(EventInfo event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCardBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: event.imagenBase64.isNotEmpty
                  ? (() {
                      try {
                        final bytes = base64Decode(event.imagenBase64);
                        return Image.memory(
                          bytes,
                          width: 80,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            width: 80,
                            height: 110,
                            child: const Icon(Icons.image_not_supported, size: 40),
                          ),
                        );
                      } catch (e) {
                        return Container(
                          width: 80,
                          height: 110,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 40),
                        );
                      }
                    })()
                  : event.imageUrl.startsWith('assets/')
                  ? Image.asset(
                      event.imageUrl,
                      width: 80,
                      height: 110,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      event.imageUrl,
                      width: 80,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 40),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.categoria,
                    style: const TextStyle(
                      color: kPrimaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _iconText(Icons.calendar_month, _formatDate(event.fecha)),
                  _iconText(Icons.location_on_outlined, event.ubicacion),
                  _iconText(Icons.people, '${event.inscritos} inscritos'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return 'Sin fecha';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate.split('T').first;
    }
  }

  Widget _iconText(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: kSecondaryTextColor, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: kSecondaryTextColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onNavBarTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: kCardBackgroundColor,
      selectedItemColor: kPrimaryGreen,
      unselectedItemColor: kSecondaryTextColor,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Eventos',
        ),
        BottomNavigationBarItem(
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _selectedIndex == 2
                  ? kPrimaryGreen.withOpacity(0.1)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              color: _selectedIndex == 2 ? kPrimaryGreen : kSecondaryTextColor,
            ),
          ),
          label: 'Perfil',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Comunidad',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.play_arrow),
          activeIcon: Icon(Icons.play_arrow_outlined),
          label: 'Entrenar',
        ),
      ],
    );
  }
}
