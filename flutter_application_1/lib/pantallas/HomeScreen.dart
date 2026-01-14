import 'package:flutter/material.dart';
import '../servicios/AuthService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:convert';
import 'EventDetailScreen.dart';
import 'package:flutter_application_1/modelos/EventModel.dart';
// IMPORTANTE: Asegúrate de tener este archivo creado o el código dará error
import 'AdminUserScreen.dart';

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
  double _kmSemana = 0;
  int _racha = 0;
  int _eventos = 0;

  // --- NUEVA VARIABLE DE ESTADO ---
  bool _isAdmin = false;
  bool _isVerified = false;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sessionsSubHome;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSubHome;

  /// EVENTOS PARA LA SECCIÓN
  List<EventModel> _proximosEventos = [];
  bool _loadingEventos = true;

  @override
  void initState() {
    super.initState();
    _loadUserName(); // <--- CARGAR NOMBRE AL INICIAR
    _listenToUserStats();
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
          .map((doc) => EventModel.fromFirestore(doc))
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

  void _listenToUserStats() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Escuchamos el doc de usuario para contar eventos y VERIFICAR ROL
    _profileSubHome = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;
            final data = snap.data();
            if (data != null) {
              // 1. Contar eventos
              int eventsCount = 0;
              if (data['myEventIds'] != null && data['myEventIds'] is List) {
                eventsCount = (data['myEventIds'] as List).length;
              }

              // 2. Verificar si es Admin (Miramos el campo 'role' definido en tu UserModel)
              bool adminStatus = false;
              if (data.containsKey('role') && data['role'] == 'admin') {
                adminStatus = true;
              }

              // 3. Verificar si es Verificado
              bool verifiedStatus = false;
              if (data.containsKey('isVerified') && data['isVerified'] == true) {
                verifiedStatus = true;
              }

              setState(() {
                _eventos = eventsCount;
                _isAdmin = adminStatus; // Actualizamos el estado
                _isVerified = verifiedStatus;
              });
            }
          },
          onError: (e) {
            print('Home profile listen error: $e');
          },
        );

    // Escuchamos sesiones para calcular km esta semana y racha
    _sessionsSubHome = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .snapshots()
        .listen(
          (qs) {
            if (!mounted) return;
            final now = DateTime.now();
            final weekStart = DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(Duration(days: now.weekday - 1));
            double weeklyDistance = 0.0;
            Set<String> days = {};

            for (final doc in qs.docs) {
              final data = doc.data();
              if (data['date'] == null) continue;
              DateTime date;
              final d = data['date'];
              if (d is Timestamp) {
                date = d.toDate();
              } else if (d is DateTime) {
                date = d;
              } else
                continue;

              if (!date.isBefore(weekStart)) {
                weeklyDistance += (data['distance_km'] ?? data['distance'] ?? 0)
                    .toDouble();
              }

              final key =
                  "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
              days.add(key);
            }

            int streak = 0;
            DateTime cursor = DateTime(now.year, now.month, now.day);
            while (true) {
              final key =
                  "${cursor.year.toString().padLeft(4, '0')}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}";
              if (days.contains(key)) {
                streak++;
                cursor = cursor.subtract(const Duration(days: 1));
              } else
                break;
            }

            setState(() {
              _kmSemana = weeklyDistance;
              _racha = streak; // racha actual en días
            });
          },
          onError: (e) {
            print('Home sessions listen error: $e');
          },
        );
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
                  _buildQuickAccess(), // YA CONTIENE LÓGICA ADMIN
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
                  Row(
                    children: [
                      Text(
                        _fullName, // ← NOMBRE REAL
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isVerified) ...[
                        const SizedBox(width: 8),
                         // Fondo blanco circular para que resalte el azul
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2), // Borde blanco
                          child: const Icon(
                            Icons.verified,
                            color: Colors.blueAccent, 
                            size: 20
                          ),
                        ),
                      ],
                    ],
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
            children: [
              Expanded(
                child: _buildStatCard(
                  Icons.schedule,
                  'Esta semana',
                  _kmSemana.toStringAsFixed(1),
                  'kms',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _buildStatCard(
                  Icons.local_fire_department,
                  'Racha',
                  _racha.toString(),
                  null,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _buildStatCard(
                  Icons.emoji_events,
                  'Eventos',
                  _eventos.toString(),
                  null,
                ),
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
    return Container(
      constraints: const BoxConstraints(
        minHeight: 120, // ← hace la tarjeta más grande y uniforme
      ),
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
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
          const SizedBox(height: 10),

          // Valor + unidad
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit != null) const SizedBox(width: 4),
              if (unit != null)
                Text(
                  unit,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Sección de "Acceso rápido" - MODIFICADA PARA ADMIN
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

          // --- PRIMERA FILA (Eventos y Comunidad) ---
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

          // --- SEGUNDA FILA (CONDICIONAL ADMIN) ---
          if (_isAdmin)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/TrainingScreen'),
                    child: _buildAccessCard(
                      Icons.fitness_center,
                      'Entrenar',
                      'Planes',
                      kAccentOrange,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/AdminUserScreen'),
                    child: _buildAccessCard(
                      Icons.manage_accounts,
                      'Gestión',
                      'Usuarios',
                      Colors.indigo, // Color distintivo para Admin
                    ),
                  ),
                ),
              ],
            )
          else
            // SI NO ES ADMIN: Diseño original centrado
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
            const Center(child: CircularProgressIndicator())
          else if (_proximosEventos.isEmpty)
            const Center(child: Text('No hay eventos disponibles'))
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

  /// Tarjeta individual para un "Evento"
  Widget _buildEventCard(EventModel evento) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailScreen(event: evento)),
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
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 40,
                            ),
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
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return Positioned(
      top: statusBarHeight + 10,
      right: 16,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
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
        _toggleNotifications();
      },
    );
  }

  /// Barra de Navegación Inferior
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
        // Ítem de Perfil (Central y estilizado)
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

  @override
  void dispose() {
    _sessionsSubHome?.cancel();
    _profileSubHome?.cancel();
    super.dispose();
  }
}
