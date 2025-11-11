import 'package:flutter/material.dart';

// --- Definición de Colores (Reutilizados de tu HomeScreen) ---
const Color kPrimaryGreen = Color(0xFF3A7D6E);
const Color kLightGreenBackground = Color(0xFFF0F5F3);
const Color kCardBackgroundColor = Colors.white;
const Color kPrimaryTextColor = Color(0xFF333333);
const Color kSecondaryTextColor = Color(0xFF666666);
const Color kAccentOrange = Color(0xFFE67E22);
const Color kAccentGreen = Color(0xFF27AE60);
const Color kAccentBlue = Color(0xFF2980B9);

/// Modelo de datos simple para un evento
class EventInfo {
  final String imagePath;
  final String tag;
  final String tagType;
  final Color tagColor;
  final String title;
  final String dateTime;
  final String location;
  final int participants;

  EventInfo({
    required this.imagePath,
    required this.tag,
    required this.tagType,
    required this.tagColor,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.participants,
  });
}

class EventosScreen extends StatefulWidget {
  const EventosScreen({Key? key}) : super(key: key);

  @override
  _EventosScreenState createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  // 0 = Todos los eventos, 1 = Mis eventos
  int _selectedToggleIndex = 0;
  int _selectedNavBarIndex = 1; // "Eventos" está seleccionado

  void _onNavBarTapped(int index) {
    setState(() {
      _selectedNavBarIndex = index;
    });
    // Aquí puedes manejar la navegación real
    if (index == 0) {
      Navigator.pushNamed(context, '/HomeScreen'); // Ir a Home
    } else if (index == 2) {
      Navigator.pushNamed(context, '/ProfileScreen'); // Ir a Perfil
    } else if (index == 3) {
      Navigator.pushNamed(context, '/CommunityScreen'); // Ir a Comunidad
    } else if (index == 4) {
      Navigator.pushNamed(context, '/TrainingScreen'); // Ir a Entrenar
    }
  }
  // --- Datos de Muestra ---
  final List<EventInfo> _allEvents = [
    EventInfo(
      imagePath: 'assets/event_maraton.png', // Reemplaza con tu asset
      tag: 'Carrera',
      tagType: 'Maratón',
      tagColor: kAccentGreen,
      title: 'Maratón Ciudad de Loja',
      dateTime: '15 de febrero • 6:00 a. m.',
      location: 'Centro de Loja',
      participants: 245,
    ),
    EventInfo(
      imagePath: 'assets/event_podocarpo.png', // Reemplaza con tu asset
      tag: 'Carrera',
      tagType: 'Camino',
      tagColor: kAccentGreen,
      title: 'Podocarpo para correr por senderos',
      dateTime: '22 de febrero • 7:00 a. m.',
      location: 'Parque Podocarpo...',
      participants: 89,
    ),
    EventInfo(
      imagePath: 'assets/event_nutricion.png', // Reemplaza con tu asset
      tag: 'Taller',
      tagType: 'Educativo',
      tagColor: kAccentOrange,
      title: 'Taller de Nutrición Deportiva',
      dateTime: '28 de febrero • 15:00',
      location: 'Centro Deportivo Municip...',
      participants: 45,
    ),
    EventInfo(
      imagePath: 'assets/event_campana.png', // Reemplaza con tu asset
      tag: 'Campaña',
      tagType: 'Salud',
      tagColor: kAccentBlue,
      title: 'Campaña Corazón Saludable',
      dateTime: '5 de marzo • 8:00 a. m.',
      location: 'Parque Jipiro',
      participants: 156,
    ),
  ];

  final List<EventInfo> _myEvents = [
    EventInfo(
      imagePath: 'assets/event_maraton.png', // Reemplaza con tu asset
      tag: 'Carrera',
      tagType: 'Maratón',
      tagColor: kAccentGreen,
      title: 'Maratón Ciudad de Loja',
      dateTime: '15 de febrero • 6:00 a. m.',
      location: 'Centro de Loja',
      participants: 245,
    ),
    EventInfo(
      imagePath: 'assets/event_nutricion.png', // Reemplaza con tu asset
      tag: 'Taller',
      tagType: 'Educativo',
      tagColor: kAccentOrange,
      title: 'Taller de Nutrición Deportiva',
      dateTime: '28 de febrero • 15:00',
      location: 'Centro Deportivo Municip...',
      participants: 45,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // La lista que se muestra cambia según el índice seleccionado
    final List<EventInfo> currentList =
        _selectedToggleIndex == 0 ? _allEvents : _myEvents;

    return Scaffold(
      backgroundColor: kLightGreenBackground,
      body: Column(
        children: [
          _buildHeader(),
          // Lista de eventos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: currentList.length,
              itemBuilder: (context, index) {
                return _buildEventCard(currentList[index]);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// Construye el Header verde con el título y el selector
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
          // Fila de Título y Botón "+"
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
                  // Lógica para añadir un nuevo evento
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Selector de Toggle
          _buildToggleButton(),
        ],
      ),
    );
  }

  /// Construye el selector "Todos los eventos" / "Mis eventos"
  Widget _buildToggleButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildToggleItem(0, 'Todos los eventos'),
          _buildToggleItem(1, 'Mis eventos'),
        ],
      ),
    );
  }

  /// Item individual del selector
  Widget _buildToggleItem(int index, String text) {
    final bool isSelected = _selectedToggleIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedToggleIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? kCardBackgroundColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? kPrimaryGreen : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  /// Construye la tarjeta para cada evento en la lista
  Widget _buildEventCard(EventInfo event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Imagen del Evento
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              event.imagePath,
              width: 80,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 110,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Columna de Detalles
          Expanded(
            child: SizedBox(
              height: 110, // Para alinear con la imagen
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tags
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: event.tagColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.tag,
                          style: TextStyle(
                            color: event.tagColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        event.tagType,
                        style: TextStyle(color: kSecondaryTextColor, fontSize: 10),
                      ),
                    ],
                  ),
                  // Título
                  Text(
                    event.title,
                    style: TextStyle(
                      color: kPrimaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Fecha y Hora
                  _buildIconText(Icons.calendar_today_outlined, event.dateTime),
                  // Ubicación y Participantes
                  Row(
                    children: [
                      Expanded(
                        child: _buildIconText(Icons.location_on_outlined, event.location),
                      ),
                      Expanded(
                        child: _buildIconText(Icons.person_outline, '${event.participants}'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Botón "Ver más"
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Lógica para ver detalles del evento
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                child: const Column(
                  children: [
                    Text('Ver', style: TextStyle(fontSize: 12)),
                    Text('más', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper para crear una fila de Icono + Texto
  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: kSecondaryTextColor, size: 12),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: kSecondaryTextColor, fontSize: 11),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  /// Barra de Navegación Inferior (Reutilizada de HomeScreen)
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedNavBarIndex,
      onTap: _onNavBarTapped,
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
              color: _selectedNavBarIndex == 2
                  ? kPrimaryGreen.withOpacity(0.1)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              color: _selectedNavBarIndex == 2 ? kPrimaryGreen : kSecondaryTextColor,
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