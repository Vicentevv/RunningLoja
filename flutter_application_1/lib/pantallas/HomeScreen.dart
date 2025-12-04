import 'package:flutter/material.dart';
import '../servicios/AuthService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'EventDetailScreen.dart';
import 'EventosScreen.dart' show EventInfo;

// --- Definición de Colores ---
const Color kPrimaryGreen = Color(0xFF3A7D6E);
const Color kLightGreenBackground = Color(0xFFF0F5F3);
const Color kCardBackgroundColor = Colors.white;
const Color kPrimaryTextColor = Color(0xFF333333);
const Color kSecondaryTextColor = Color(0xFF666666);
const Color kAccentOrange = Color(0xFFE67E22);
const Color kAccentBlue = Color(0xFF3498DB);
const Color kAccentDarkGreen = Color(0xFF2E7D32);

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _showNotifications = false;

  /// ESTE NOMBRE ES EL QUE SE VA A MOSTRAR EN EL HEADER
  String _fullName = "Cargando...";
  String _profilePic = "";
  double _kmSemana = 0;
  int _calorias = 0;
  int _eventos = 0;

  /// EVENTOS PARA LA SECCIÓN
  List<EventInfo> _proximosEventos = [];
  bool _loadingEventos = true;

  @override
  void initState() {
    super.initState();
    _loadUserName(); // <--- CARGAR NOMBRE AL INICIAR
    _loadUpcomingEvents(); // <--- CARGAR PRÓXIMOS EVENTOS
  }

  /// ----------------------------------------------------------
  /// FUNCIÓN PARA CARGAR LOS 3 PRÓXIMOS EVENTOS
  /// ----------------------------------------------------------
  Future<void> _loadUpcomingEvents() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('eventos')
          .orderBy('fecha')
          .limit(3)
          .get();

      final eventos = snapshot.docs
          .map((doc) => EventInfo.fromFirestore(doc))
          .toList();

      if (!mounted) return;
      setState(() {
        _proximosEventos = eventos;
        _loadingEventos = false;
      });
    } catch (e) {
      print("ERROR cargando eventos: $e");
      if (!mounted) return;
      setState(() {
        _loadingEventos = false;
      });
    }
  }

  /// ----------------------------------------------------------
  /// FUNCIÓN PARA CARGAR EL NOMBRE DEL USUARIO LOGUEADO
  /// ----------------------------------------------------------
  Future<void> _loadUserName() async {
    try {
      final auth = AuthService();
      final snapshot = await auth.getUserData();

      if (snapshot != null && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;

        if (!mounted) return;
        setState(() {
          _fullName = data["fullName"] ?? "Usuario";
        });
      } else {
        if (!mounted) return;
        setState(() {
          _fullName = "Usuario";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fullName = "Usuario";
        });
      }
      print("ERROR cargando nombre: $e");
    }
  }

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) Navigator.pushNamed(context, '/EventosScreen');
    if (index == 2) Navigator.pushNamed(context, '/ProfileScreen');
    if (index == 3) Navigator.pushNamed(context, '/CommunityScreen');
    if (index == 4) Navigator.pushNamed(context, '/TrainingScreen');
  }

  void _toggleNotifications() {
    setState(() {
      _showNotifications = !_showNotifications;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightGreenBackground,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (_showNotifications) _toggleNotifications();
            },
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(), // YA MUESTRA EL NOMBRE REAL
                  _buildQuickAccess(),
                  _buildUpcomingEvents(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          if (_showNotifications) _buildNotificationPanel(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// ----------------------------------------------------------
  /// HEADER -> Reemplazo SOLO el nombre
  /// ----------------------------------------------------------
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ---------- FILA SUPERIOR (Nombre + Foto + Notificaciones) ----------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// NOMBRE Y SALUDO
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¡Hola!',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    _fullName, // ← NOMBRE REAL
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              /// NOTIFICACIONES
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: _toggleNotifications,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text(
            '¡Listo para tu próxima carrera! 🏃',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),

          const SizedBox(height: 24),

          /// ---------- ESTADÍSTICAS REALES ----------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                Icons.schedule,
                'Esta semana',
                _kmSemana.toString(), // ← desde Firestore
                'KMS',
              ),
              _buildStatCard(
                Icons.local_fire_department,
                'Calorías',
                _calorias.toString(), // ← desde Firestore
                null,
              ),
              _buildStatCard(
                Icons.emoji_events,
                'Eventos',
                _eventos.toString(), // ← desde Firestore
                null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tarjeta individual para las estadísticas en el header
  Widget _buildStatCard(
    IconData icon,
    String title,
    String value,
    String? unit,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
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
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
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
                  Text(
                    unit,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Sección de "Acceso rápido"
  Widget _buildQuickAccess() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acceso rápido',
            style: TextStyle(
              color: kPrimaryTextColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Primera fila con 2 tarjetas
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/EventosScreen'),
                  child: _buildAccessCard(
                    Icons.event,
                    'Eventos',
                    'Próximas carreras',
                    kAccentDarkGreen,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/CommunityScreen'),
                  child: _buildAccessCard(
                    Icons.people,
                    'Comunidad',
                    'Conecta con corredores',
                    kAccentBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Segunda fila con tarjeta centrada
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.51,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/TrainingScreen'),
                child: _buildAccessCard(
                  Icons.fitness_center,
                  'Entrenar',
                  'Planes de entrenamiento',
                  kAccentOrange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta individual para el "Acceso rápido"
  Widget _buildAccessCard(
    IconData icon,
    String title,
    String subtitle,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: kPrimaryTextColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: kSecondaryTextColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Sección de "Próximos eventos"
  Widget _buildUpcomingEvents() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Próximos eventos',
                style: TextStyle(
                  color: kPrimaryTextColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/EventosScreen'),
                child: const Text(
                  'Ver todos',
                  style: TextStyle(
                    color: kPrimaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loadingEventos)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_proximosEventos.isEmpty)
            const Center(
              child: Text('No hay eventos disponibles'),
            )
          else
            Column(
              children: _proximosEventos
                  .map((evento) => _buildEventCard(evento))
                  .toList(),
            ),
        ],
      ),
    );
  }

  /// Tarjeta individual para un "Evento" - IDÉNTICA A EventosScreen
  Widget _buildEventCard(
    EventInfo evento,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(event: evento),
          ),
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
              child: evento.imagenBase64.isNotEmpty
                  ? (() {
                      try {
                        final bytes = base64Decode(evento.imagenBase64);
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
                        // Si falla la decodificación, mostramos placeholder seguro
                        return Container(
                          width: 80,
                          height: 110,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 40),
                        );
                      }
                    })()
                  : evento.imageUrl.startsWith('assets/')
                      ? Image.asset(
                          evento.imageUrl,
                          width: 80,
                          height: 110,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          evento.imageUrl,
                          width: 80,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported,
                                size: 40),
                          ),
                        ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evento.categoria,
                    style: const TextStyle(
                      color: kPrimaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    evento.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _iconText(Icons.calendar_month, evento.fecha),
                  _iconText(Icons.location_on_outlined, evento.ubicacion),
                  _iconText(Icons.people, '${evento.inscritos} inscritos'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper para mostrar icon + text
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

  /// Panel de Notificaciones que se superpone
  Widget _buildNotificationPanel() {
    // Obtenemos la altura del padding superior (área de la barra de estado)
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return Positioned(
      top: statusBarHeight + 10, // Se posiciona debajo de la barra de estado
      right: 16,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85, // 85% del ancho
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Notificaciones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryTextColor,
                  ),
                ),
              ),
              _buildNotificationItem(
                Icons.event_available,
                kAccentDarkGreen,
                'Nuevo evento disponible',
                'Maratón Ciudad de Loja - Inscripciones abiertas',
                '2 minutos',
                true,
              ),
              _buildNotificationItem(
                Icons.person_add,
                kAccentBlue,
                'Nuevo seguidor',
                'Maria González comenzó a seguirte',
                '15 minutos',
                false,
              ),
              _buildNotificationItem(
                Icons.emoji_events,
                kAccentOrange,
                '¡Logro desbloqueado!',
                'Has puesto 50 km este mes',
                '1 hora',
                false,
              ),
              _buildNotificationItem(
                Icons.alarm,
                Colors.redAccent,
                'Recordatorio de entrenamiento',
                'Es hora de tu carrera matutina',
                '2 horas',
                false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Item individual para la lista de notificaciones
  Widget _buildNotificationItem(
    IconData icon,
    Color iconColor,
    String title,
    String subtitle,
    String time,
    bool hasDot,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Row(
        children: [
          if (hasDot)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: const BoxDecoration(
                color: kAccentBlue,
                shape: BoxShape.circle,
              ),
            ),
          Expanded(
            child: Text(
              subtitle,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: Text(
        time,
        style: const TextStyle(color: kSecondaryTextColor, fontSize: 10),
      ),
      onTap: () {
        // Lógica al tocar una notificación
        _toggleNotifications(); // Cierra el panel
      },
    );
  }

  /// Barra de Navegación Inferior
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onNavBarTap,
      type: BottomNavigationBarType.fixed, // Muestra todos los labels
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
        // Ítem de Perfil (Central y estilizado)
        BottomNavigationBarItem(
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // El círculo verde solo aparece cuando está activo
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
