import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/modelos/UserModel.dart';
import 'package:flutter_application_1/pantallas/EditProfileScreen.dart';
import 'package:flutter_application_1/servicios/AuthService.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // para leer/guardar perfil
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

// --- Definición de Colores ---
const Color kPrimaryGreen = Color(0xFF3A7D6E);
const Color kCardBackgroundColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFF666666);
const Color kLightGrayBackground = Color(0xFFF4F6F8);
const Color kPrimaryTextColor = Color(0xFF333333);

// Puedes ejecutar esta aplicación pegando este código en tu archivo main.dart
// de un proyecto Flutter nuevo.
void main() {
  runApp(const ProfileApp());
}

class ProfileApp extends StatelessWidget {
  const ProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perfil de Corredor',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: kLightGrayBackground,
        fontFamily: 'Roboto',
        // --- TEMA PARA LA NUEVA PANTALLA DE EDICIÓN ---
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          prefixIconColor: kPrimaryGreen,
        ),
        // ---
      ),
      // --- RUTAS NECESARIAS PARA QUE LA NAVEGACIÓN INFERIOR FUNCIONE ---
      // (Añadí esto para que el ejemplo sea funcional)
      initialRoute: '/',
      routes: {
        '/': (context) => const ProfileScreen(),
        '/HomeScreen': (context) => const PlaceholderScreen(title: 'Home'),
        '/EventosScreen': (context) =>
            const PlaceholderScreen(title: 'Eventos'),
        '/CommunityScreen': (context) =>
            const PlaceholderScreen(title: 'Comunidad'),
        '/TrainingScreen': (context) =>
            const PlaceholderScreen(title: 'Entrenar'),
      },
      // ---
      debugShowCheckedModeBanner: false,
    );
  }
}

// Pantalla de placeholder para la navegación
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Pantalla de $title')),
    );
  }
}
// --- FIN DE PLACEHOLDERS ---

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 2;

  // --- MODELO DE USUARIO EN LUGAR DE VARIABLES LOCALES ---
  UserModel? _user;

  // --- VARIABLES DE ESTADÍSTICAS CALCULADAS (MANTENIDAS COMO LOCALES YA QUE SE CALCULAN EN TIEMPO REAL) ---
  double _weeklyDistance = 0.0;
  int _currentStreak = 0;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sessionsSubProfile;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // cargar datos desde Firebase al iniciar
    _listenToSessionsForProfile();
  }

  void _listenToSessionsForProfile() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Escuchamos sesiones para calcular km esta semana y racha
    _sessionsSubProfile = FirebaseFirestore.instance
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
                  '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              days.add(key);
            }

            // calcular racha
            int streak = 0;
            DateTime cursor = DateTime(now.year, now.month, now.day);
            while (true) {
              final key =
                  '${cursor.year.toString().padLeft(4, '0')}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}';
              if (days.contains(key)) {
                streak++;
                cursor = cursor.subtract(const Duration(days: 1));
              } else
                break;
            }

            setState(() {
              _weeklyDistance = weeklyDistance;
              _currentStreak = streak;
              // también actualizamos algunos campos mostrados en la UI si el documento de usuario cambió
            });
          },
          onError: (e) {
            print('Error listening profile sessions: $e');
          },
        );
  }

  /// Carga los datos del perfil y estadísticas desde Firestore usando el modelo
  Future<void> _loadUserProfile() async {
    try {
      final auth = AuthService();
      final snapshot = await auth.getUserData();

      if (snapshot != null && snapshot.exists && snapshot.data() != null) {
        if (!mounted) return;
        setState(() {
          _user = UserModel.fromDocument(snapshot);
        });
      }
    } catch (e) {
      print("Error cargando perfil: $e");
    }
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _sessionsSubProfile?.cancel();
    super.dispose();
  }

  /// NAVEGA A LA PANTALLA DE EDICIÓN
  void _navigateToEditProfile() async {
    // Mapa con datos actuales para enviar al formulario, extraídos del modelo
    final Map<String, String> currentUserData = {
      'nombre': _user?.fullName ?? '',
      'email': _user?.email ?? '',
      'descripcion': _user?.role ?? '',
      'altura': _user?.height != null && _user!.height != 0
          ? _user!.height.toString()
          : '',
      'peso': _user?.weight != null && _user!.weight != 0
          ? _user!.weight.toString()
          : '',
      'objetivo': _user?.currentGoal ?? '',
      'avatarUrl':
          '', // No se usa directamente, pero si necesitas pasar base64: _user?.avatarBase64 ?? ''
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditProfileScreen(currentUserData: currentUserData),
      ),
    );

    if (result != null && result is Map<String, String>) {
      if (!mounted) return;
      // Actualizamos el modelo localmente con los nuevos valores (mutando los campos directamente)
      setState(() {
        if (_user != null) {
          _user!.fullName = result['nombre'] ?? _user!.fullName;
          _user!.role = result['descripcion'] ?? _user!.role;
          _user!.height =
              double.tryParse(result['altura'] ?? '') ?? _user!.height;
          _user!.weight =
              double.tryParse(result['peso'] ?? '') ?? _user!.weight;
          _user!.currentGoal = result['objetivo'] ?? _user!.currentGoal;
          // Si editas avatarBase64, agrégalo aquí: _user!.avatarBase64 = result['avatarBase64'] ?? _user!.avatarBase64;
        }
      });

      // Guardamos en Firebase
      _saveProfileToFirebase(result);
    }
  }

  /// Guarda los cambios en Firestore (Solo datos editables)
  Future<void> _saveProfileToFirebase(Map<String, String> newData) async {
    try {
      final auth = AuthService();
      final String? uid = auth
          .getCurrentUserId(); // Asegúrate de tener este método en AuthService o usa auth.currentUser?.uid

      // Si no tienes getCurrentUserId, puedes usar:
      // final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) return;

      // Convertimos Strings numéricos a int/double para la BD
      double? newHeight = double.tryParse(newData['altura'] ?? "");
      double? newWeight = double.tryParse(newData['peso'] ?? "");

      final Map<String, dynamic> updateMap = <String, dynamic>{};

      updateMap['fullName'] = newData['nombre'];
      updateMap['role'] =
          newData['descripcion']; // Mapeamos 'descripcion' a 'role' según tu BD
      updateMap['height'] = newHeight ?? 0.0;
      updateMap['weight'] = newWeight ?? 0.0;
      updateMap['currentGoal'] =
          newData['objetivo']; // Mapeamos a 'currentGoal'
      // Si editas avatarBase64, agrégalo aquí: updateMap['avatarBase64'] = newData['avatarBase64'];

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(updateMap);
    } catch (e) {
      print("Error guardando perfil: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(context),
            // El resto del contenido irá en una columna con padding
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, "Estadísticas"),
                  _buildStatsGrid(),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, "Información física"),
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, "Mis objetivos"),
                  _buildObjectivesCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, "Logros ( 8 )"),
                  _buildAchievementsGrid(),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, "Configuración"),
                  _buildSettingsList(),
                ],
              ),
            ),
          ],
        ),
      ),
      // Barra de navegación inferior
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
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
                color: _selectedIndex == 2
                    ? kPrimaryGreen.withOpacity(0.1)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                color: _selectedIndex == 2
                    ? kPrimaryGreen
                    : kSecondaryTextColor,
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
            icon: Icon(Icons.play_arrow), // ICONO CORREGIDO
            activeIcon: Icon(Icons.play_arrow_outlined), // ICONO CORREGIDO
            label: 'Entrenar',
          ),
        ],
      ),
    );
  }

  /// Maneja la navegación cuando se toca un ítem de la barra inferior
  void _onNavBarTapped(int index) {
    if (index == _selectedIndex) return; // No navegar si ya está en la pantalla

    // Usamos 'pushReplacementNamed' para evitar apilar pantallas
    // (ej. Home -> Eventos -> Home -> Eventos...)
    String routeName;
    switch (index) {
      case 0:
        routeName = '/HomeScreen';
        break;
      case 1:
        routeName = '/EventosScreen';
        break;
      case 2:
        // Ya estamos en Perfil
        return;
      case 3:
        routeName = '/CommunityScreen';
        break;
      case 4:
        routeName = '/TrainingScreen';
        break;
      default:
        return;
    }

    Navigator.pushReplacementNamed(context, routeName);
  }

  /// Widget para la cabecera verde del perfil
  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        color: Colors.teal[600],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Mi perfil",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  // --- ACCIÓN DE EDITAR ---
                  onPressed: _navigateToEditProfile,
                  // ---
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: (_user?.avatarBase64 ?? '').isNotEmpty
                    ? MemoryImage(base64Decode(_user!.avatarBase64))
                    : null,
                child: (_user?.avatarBase64 ?? '').isEmpty
                    ? Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),

              const SizedBox(width: 15),
              Expanded(
                // Añadido Expanded para evitar overflow
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _user?.fullName ?? 'Usuario',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_user?.isVerified == true) ...[
                          // ⬅️ Badge de verificado
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            color: Colors.blueAccent,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if ((_user?.email ?? '').isNotEmpty)
                      Text(
                        _user!.email,
                        style: TextStyle(color: Colors.white.withOpacity(0.9)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    if ((_user?.role ?? '').isNotEmpty)
                      Text(
                        _user!.role,
                        style: TextStyle(color: Colors.white.withOpacity(0.9)),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Título reutilizable para las secciones
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  /// Grid para la sección de estadísticas
  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      // Cambiado de 1.2 a 1.0 para dar más espacio vertical y evitar el overflow
      childAspectRatio: 1.0,
      children: [
        _buildStatItem(
          _weeklyDistance.toStringAsFixed(1),
          "km",
          "Esta semana",
          Colors.blue[700]!,
        ),
        _buildStatItem(
          _currentStreak.toString(),
          "días",
          "Racha actual",
          Colors.green[600]!,
        ),
        _buildStatItem(
          _user?.averagePace ?? '0:00',
          "min/km",
          "Ritmo",
          Colors.orange[700]!,
        ),
        _buildStatItem(
          _user?.myEventIds.length.toString() ?? '0',
          "Eventos",
          "Eventos inscritos",
          Colors.purple[600]!,
        ),
      ],
    );
  }

  /// Helper para construir cada tarjeta con sombra mejorada
  Widget _buildStatItem(String value, String unit, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // --- AQUÍ ESTÁ EL SOMBREADO INTENSIFICADO ---
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Opacidad suave
            blurRadius: 12, // Difuminado amplio
            offset: const Offset(0, 6), // Desplazamiento hacia abajo
            spreadRadius: 0, // No se expande hacia los lados
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Usamos Flexible para asegurar que el texto se ajuste si es muy grande
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Tarjeta para la "Información física"
  Widget _buildInfoCard() {
    final alturaCm = (_user?.height != null && _user!.height != 0)
        ? '${_user!.height} cm'
        : '-- cm';
    final pesoKg = (_user?.weight != null && _user!.weight != 0)
        ? '${_user!.weight} kg'
        : '-- kg';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildInfoItem(
              Icons.straighten, // <-- icono corregido
              alturaCm,
              "Altura",
            ),
            _buildInfoItem(Icons.monitor_weight_outlined, pesoKg, "Peso"),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[600], size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  /// Tarjeta para "Mis objetivos"
  Widget _buildObjectivesCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: ListTile(
        leading: const Icon(Icons.flag_outlined, color: Colors.teal),
        title: Text(
          _user?.currentGoal ?? 'Sin objetivo definido',
        ), // Del modelo
        minLeadingWidth: 0,
      ),
    );
  }

  /// Grid para la sección de "Logros"
  Widget _buildAchievementsGrid() {
    // (Sin cambios)
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildAchievedItem(
          Icons.emoji_events_outlined,
          "Primera\ncarrera",
          Colors.orange[100]!,
          Colors.orange[800]!,
        ),
        _buildAchievedItem(
          Icons.directions_run,
          "5k-10k\ncompletados",
          Colors.green[100]!,
          Colors.green[800]!,
        ),
        _buildAchievedItem(
          Icons.calendar_month_outlined,
          "Constancia\nsemanal",
          Colors.teal[100]!,
          Colors.teal[800]!,
        ),
        _buildLockedItem(Icons.speed, "Velocista"),
        _buildLockedItem(Icons.hiking, "Maratonista"),
        _buildAchievedItem(
          Icons.groups_outlined,
          "Comunidad\nactiva",
          Colors.purple[100]!,
          Colors.purple[800]!,
        ),
      ],
    );
  }

  Widget _buildAchievedItem(
    IconData icon,
    String label,
    Color bgColor,
    Color iconColor,
  ) {
    // (Sin cambios)
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedItem(IconData icon, String label) {
    // (Sin cambios)
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[500], size: 30),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta con la lista de "Configuración"
  Widget _buildSettingsList() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Column(
        children: [
          _buildSettingsItem(
            Icons.favorite_border,
            "Bienestar y consejos",
            Colors.green,
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildSettingsItem(
            Icons.notifications_none_outlined,
            "Notificaciones",
            Colors.orange,
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildSettingsItem(Icons.lock_outline, "Privacidad", Colors.blue),
          const Divider(height: 1, indent: 20, endIndent: 20),

          // 👇 ESTE ES EL IMPORTANTE
          _buildSettingsItem(
            Icons.logout,
            "Cerrar sesión",
            Colors.red,
            onTap: () async {
              await AuthService().logout();

              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/LoginScreen',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String title,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap ?? () {}, // si no envías nada, no hace nada
    );
  }
}
