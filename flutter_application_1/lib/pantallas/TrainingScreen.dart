import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:location/location.dart';

// --- Definición de Colores ---
const Color kPrimaryGreen = Color(0xFF3A7D6E);
const Color kLightGreenBackground = Color(0xFFF0F5F3);
const Color kCardBackgroundColor = Colors.white;
const Color kPrimaryTextColor = Color(0xFF333333);
const Color kSecondaryTextColor = Color(0xFF666666);
const Color kAccentOrange = Color(0xFFE67E22);

class EntrenarScreen extends StatefulWidget {
  const EntrenarScreen({Key? key}) : super(key: key);

  @override
  _EntrenarScreenState createState() => _EntrenarScreenState();
}

class _EntrenarScreenState extends State<EntrenarScreen> {
  int _selectedNavBarIndex = 4; // 4 es 'Entrenar'
  int _selectedTabIndex = 0; // 0 es 'Inicio'
  bool _isTraining = false; // Estado para saber si se está entrenando

  // --- Para el Calendario ---
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  // Simulación de días de racha
  final Set<DateTime> _streakDays = {
    DateTime.now().subtract(const Duration(days: 1)),
    DateTime.now().subtract(const Duration(days: 2)),
    DateTime.now().subtract(const Duration(days: 4)),
  };

  // --- Para el Mapa y Ubicación ---
  GoogleMapController? _mapController;
  Location _location = Location();
  LatLng _currentPosition = const LatLng(3.9936, -79.2045); // Posición inicial (Loja)
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _requestLocationPermission();
  }

  // Solicita permiso y obtiene la ubicación actual
  void _requestLocationPermission() async {
    setState(() {
      _isLoadingLocation = true;
    });
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }
    }

    final locationData = await _location.getLocation();
    setState(() {
      _currentPosition = LatLng(locationData.latitude!, locationData.longitude!);
      _isLoadingLocation = false;
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_currentPosition),
      );
    });
  }

  void _onNavBarTap(int index) {
    setState(() {
      _selectedNavBarIndex = index;
    });
    if (index == 0) {
      Navigator.pushNamed(context, '/HomeScreen');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/EventosScreen');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/ProfileScreen');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/CommunityScreen');
    } else if (index == 4) {
      Navigator.pushNamed(context, '/TrainingScreen');
    }
  }

  void _onTopTabTap(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  // --- Funciones para Iniciar/Parar ---
  void _startTraining() {
    setState(() {
      _isTraining = true;
    });
    // Inicia el listener de ubicación si no lo has hecho
    _location.onLocationChanged.listen((LocationData currentLocation) {
      if (!_isTraining) return;
      setState(() {
        _currentPosition = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_currentPosition),
        );
      });
    });
  }

  void _stopTraining() {
    setState(() {
      _isTraining = false;
    });
    // Aquí guardarías el entrenamiento
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightGreenBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildTopTabBar(),
            _buildTabContent(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// Header verde con estadísticas
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      decoration: const BoxDecoration(
        color: kPrimaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Fila de Título y Cámara
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Entrenar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 28),
                onPressed: () {
                  // Lógica para abrir la cámara
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Fila de Tarjetas de Estadísticas
          Row(
            children: [
              _buildStatCard(Icons.directions_run, 'Esta semana', '23.6', 'kilómetros'),
              const SizedBox(width: 16),
              _buildStatCard(Icons.local_fire_department, 'Racha actual', '5', 'días 🔥'),
            ],
          ),
        ],
      ),
    );
  }

  /// Tarjeta individual para las estadísticas en el header
  Widget _buildStatCard(IconData icon, String title, String value, String? unit) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unit != null) const SizedBox(width: 4),
                if (unit != null)
                  Expanded(
                    child: Text(
                      unit,
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  /// Barra de Toggles (Inicio, Histórico, Calendario, Rutas)
  Widget _buildTopTabBar() {
    final List<String> labels = ['Inicio', 'Histórico', 'Calendario', 'Rutas'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(labels.length, (index) {
          final bool isSelected = _selectedTabIndex == index;
          return ChoiceChip(
            label: Text(labels[index]),
            selected: isSelected,
            onSelected: (bool selected) {
              if (selected) {
                _onTopTabTap(index);
              }
            },
            backgroundColor: kLightGreenBackground,
            selectedColor: kPrimaryGreen,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : kPrimaryTextColor,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? kPrimaryGreen : Colors.grey.shade300,
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Contenido dinámico según el Tab seleccionado
  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: // Inicio
        return _buildInicioTab();
      case 1: // Histórico
        return _buildHistoricoTab();
      case 2: // Calendario
        return _buildCalendarioTab();
      case 3: // Rutas
        return _buildRutasTab();
      default:
        return _buildInicioTab();
    }
  }

  // --- CONTENIDO DE CADA TAB ---

  Widget _buildInicioTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLiveTrainingCard(),
          const SizedBox(height: 24),
          _buildWeekSummaryCard(),
          const SizedBox(height: 24),
          _buildSuggestedWorkoutsCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHistoricoTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text('Aquí se mostrará tu historial de entrenamientos.',
            textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildCalendarioTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay; // actualiza el foco
            });
          },
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          // --- Marcador de Racha ---
          eventLoader: (day) {
            // Normaliza el día para la comparación
            final normalizedDay = DateTime.utc(day.year, day.month, day.day);
            if (_streakDays.contains(normalizedDay)) {
              return ['racha']; // Retorna una lista no vacía si es un día de racha
            }
            return [];
          },
          calendarStyle: CalendarStyle(
            // Estilo para los marcadores de eventos (racha)
            markerDecoration: const BoxDecoration(
              color: kAccentOrange,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: kPrimaryGreen.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: kPrimaryGreen,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              color: kPrimaryTextColor,
              fontSize: 18,
              fontWeight: FontWeight.bold
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRutasTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text('Aquí podrás explorar y guardar nuevas rutas.',
            textAlign: TextAlign.center),
      ),
    );
  }

  // --- TARJETAS DEL TAB "INICIO" ---

  /// Card de "Entrenamiento en vivo" (dinámico)
  Widget _buildLiveTrainingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        width: double.infinity,
        child: _isTraining
            ? _buildTrainingActiveView() // Vista cuando se está entrenando
            : _buildTrainingIdleView(), // Vista antes de entrenar
      ),
    );
  }

  /// Vista de "Entrenamiento en vivo" (IDLE / INACTIVO)
  Widget _buildTrainingIdleView() {
    return Column(
      children: [
        const Text(
          'Entrenamiento en vivo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kPrimaryTextColor,
          ),
        ),
        const SizedBox(height: 24),
        Icon(
          Icons.play_circle_outline,
          color: kPrimaryGreen.withOpacity(0.5),
          size: 80,
        ),
        const SizedBox(height: 16),
        const Text(
          '¿Listo para entrenar?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kSecondaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Inicia tu entrenamiento y registra tu progreso',
          style: TextStyle(color: kSecondaryTextColor, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.timer_outlined, color: Colors.white),
          label: const Text('Iniciar entrenamiento'),
          onPressed: _startTraining,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// Vista de "Entrenamiento en vivo" (ACTIVO)
  Widget _buildTrainingActiveView() {
    return Column(
      children: [
        const Text(
          'Entrenamiento en vivo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kPrimaryTextColor,
          ),
        ),
        const SizedBox(height: 16),
        // --- MAPA ---
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _isLoadingLocation
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition,
                      zoom: 15,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                  ),
          ),
        ),
        const SizedBox(height: 24),
        // --- Estadísticas en vivo (simuladas) ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLiveStat("RITMO", "5:30", "/km"),
            _buildLiveStat("TIEMPO", "12:05", ""),
            _buildLiveStat("DISTANCIA", "2.18", "km"),
          ],
        ),
        const SizedBox(height: 24),
        // --- Botón de Parar ---
        ElevatedButton.icon(
          icon: const Icon(Icons.stop, color: Colors.white),
          label: const Text('Parar entrenamiento'),
          onPressed: _stopTraining,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent, // Botón de parar en rojo
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  static Widget _buildLiveStat(String title, String value, String unit) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: kSecondaryTextColor, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: kPrimaryTextColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (unit.isNotEmpty)
          Text(
            unit,
            style: const TextStyle(color: kSecondaryTextColor, fontSize: 12),
          ),
      ],
    );
  }

  /// Card de "Resumen de la semana"
  Widget _buildWeekSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de la semana',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kPrimaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(Icons.timer_outlined, '2:10:50', 'Tiempo total'),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                _buildSummaryItem(Icons.speed_outlined, '5:31 /km', 'Ritmo'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: kPrimaryGreen, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: kPrimaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: kSecondaryTextColor, fontSize: 12),
        ),
      ],
    );
  }

  /// Card de "Entrenamientos sugeridos"
  Widget _buildSuggestedWorkoutsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entrenamientos sugeridos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kPrimaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildWorkoutItem(Icons.electric_bolt, 'Intervalos 5x1000m', '45 min • Alta intensidad'),
            const Divider(height: 24),
            _buildWorkoutItem(Icons.directions_run, 'Carrera larga', '90 min • Baja intensidad'),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: kPrimaryGreen.withOpacity(0.1),
          child: Icon(icon, color: kPrimaryGreen),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: kPrimaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: kSecondaryTextColor, fontSize: 14),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('Iniciar', style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  /// Barra de Navegación Inferior
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedNavBarIndex,
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
              color: _selectedNavBarIndex == 2 ? kPrimaryGreen.withOpacity(0.1) : Colors.transparent,
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