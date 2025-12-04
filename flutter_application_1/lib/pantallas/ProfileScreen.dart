import 'package:flutter/material.dart';
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

  // --- VARIABLES DE DATOS DEL PERFIL ---
  String _nombre = '';
  String _email = '';
  String _descripcion = '';
  String _avatarUrl = '';
  String _alturaCm = '--'; // Valor por defecto visual
  String _pesoKg = '--';   // Valor por defecto visual
  String _objetivo = '';

  // --- VARIABLES DE ESTADÍSTICAS (NUEVAS) ---
  String _distanciaTotal = "0";
  String _totalCarreras = "0";
  String _ritmoPromedio = "0:00";
  String _totalEventos = "0";
  // Estadísticas calculadas en tiempo real
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
        .listen((qs) {
      if (!mounted) return;
      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
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
        } else continue;

        if (!date.isBefore(weekStart)) {
          weeklyDistance += (data['distance_km'] ?? data['distance'] ?? 0).toDouble();
        }

        final key = '${date.year.toString().padLeft(4,'0')}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
        days.add(key);
      }

      // calcular racha
      int streak = 0;
      DateTime cursor = DateTime(now.year, now.month, now.day);
      while (true) {
        final key = '${cursor.year.toString().padLeft(4,'0')}-${cursor.month.toString().padLeft(2,'0')}-${cursor.day.toString().padLeft(2,'0')}';
        if (days.contains(key)) {
          streak++;
          cursor = cursor.subtract(const Duration(days: 1));
        } else break;
      }

      setState(() {
        _weeklyDistance = weeklyDistance;
        _currentStreak = streak;
        // también actualizamos algunos campos mostrados en la UI si el documento de usuario cambió
      });
    }, onError: (e) {
      print('Error listening profile sessions: $e');
    });
  }

  /// Carga los datos del perfil y estadísticas desde Firestore
  Future<void> _loadUserProfile() async {
    try {
      final auth = AuthService();
      final snapshot = await auth.getUserData();

      if (snapshot != null && snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;

        if (!mounted) return;
        setState(() {
          // --- DATOS PERSONALES ---
          _nombre = data["fullName"] ?? _nombre;
          _email = data["email"] ?? _email;
          _descripcion = data["role"] ?? _descripcion; // Usamos 'role' como descripción o el campo que prefieras
          
          // Conversión segura de números a String para altura y peso
          _alturaCm = (data["height"] != null && data["height"] != 0) 
              ? data["height"].toString() 
              : "--";
          
          _pesoKg = (data["weight"] != null && data["weight"] != 0) 
              ? data["weight"].toString() 
              : "--";
              
          _objetivo = data["currentGoal"] ?? "Sin objetivo definido";

          if (data["photoUrl"] != null && data["photoUrl"].toString().isNotEmpty) {
            _avatarUrl = data["photoUrl"];
          }

          // --- ESTADÍSTICAS (NUEVO) ---
          
          // 1. Distancia Total (totalDistance)
          if (data["totalDistance"] != null) {
            // Convertimos a String, si quieres formatear decimales puedes usar .toStringAsFixed(1)
            _distanciaTotal = data["totalDistance"].toString();
          }

          // 2. Carreras Totales (totalRuns)
          if (data["totalRuns"] != null) {
            _totalCarreras = data["totalRuns"].toString();
          }

          // 3. Ritmo Promedio (averagePace)
          _ritmoPromedio = data["averagePace"] ?? "0:00";

          // 4. Eventos (myEventIds es un array, contamos su longitud)
          if (data["myEventIds"] != null && data["myEventIds"] is List) {
            _totalEventos = (data["myEventIds"] as List).length.toString();
          }
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
    // Mapa con datos actuales para enviar al formulario
    final Map<String, String> currentUserData = {
      'nombre': _nombre,
      'email': _email,
      'descripcion': _descripcion,
      'altura': _alturaCm == "--" ? "" : _alturaCm, // Enviamos vacío si es -- para que no estorbe al editar
      'peso': _pesoKg == "--" ? "" : _pesoKg,
      'objetivo': _objetivo,
      'avatarUrl': _avatarUrl,
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
      // Actualizamos UI localmente
      setState(() {
        _nombre = result['nombre'] ?? _nombre;
        // _email = result['email'] ?? _email; // Generalmente el email no se cambia aquí
        _descripcion = result['descripcion'] ?? _descripcion;
        _alturaCm = result['altura']?.isEmpty ?? true ? "--" : result['altura']!;
        _pesoKg = result['peso']?.isEmpty ?? true ? "--" : result['peso']!;
        _objetivo = result['objetivo'] ?? _objetivo;
      });

      // Guardamos en Firebase
      _saveProfileToFirebase(result);
    }
  }

  /// Guarda los cambios en Firestore (Solo datos editables)
  Future<void> _saveProfileToFirebase(Map<String, String> newData) async {
    try {
      final auth = AuthService();
      final String? uid = auth.getCurrentUserId(); // Asegúrate de tener este método en AuthService o usa auth.currentUser?.uid
      
      // Si no tienes getCurrentUserId, puedes usar:
      // final uid = FirebaseAuth.instance.currentUser?.uid; 
      
      if (uid == null) return;

      // Convertimos Strings numéricos a int/double para la BD
      int? newHeight = int.tryParse(newData['altura'] ?? "");
      int? newWeight = int.tryParse(newData['peso'] ?? "");

      final Map<String, dynamic> updateMap = <String, dynamic>{};
      
      updateMap['fullName'] = newData['nombre'];
      updateMap['role'] = newData['descripcion']; // Mapeamos 'descripcion' a 'role' según tu BD
      updateMap['height'] = newHeight ?? 0;
      updateMap['weight'] = newWeight ?? 0;
      updateMap['currentGoal'] = newData['objetivo']; // Mapeamos a 'currentGoal'

      await FirebaseFirestore.instance.collection('users').doc(uid).update(updateMap);
      
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
                radius: 35,
                backgroundColor: _avatarUrl.isNotEmpty
                    ? Colors.white.withOpacity(0.3)
                    : kPrimaryGreen.withOpacity(0.8),
                backgroundImage:
                    _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                child: _avatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                // Añadido Expanded para evitar overflow
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nombre.isNotEmpty ? _nombre : 'Usuario',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_email.isNotEmpty)
                      Text(
                        _email,
                        style: TextStyle(color: Colors.white.withOpacity(0.9)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    if (_descripcion.isNotEmpty)
                      Text(
                        _descripcion,
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
      childAspectRatio: 1.8,
      children: [
        _buildStatItem(
          _weeklyDistance.toStringAsFixed(1), // km esta semana
          "km",
          "Esta semana",
          Colors.blue[700]!,
        ),
        _buildStatItem(
          _currentStreak.toString(), // racha actual
          "días",
          "Racha actual",
          Colors.green[600]!,
        ),
        _buildStatItem(
          _ritmoPromedio, // Variable conectada a DB
          "min/km",
          "Ritmo",
          Colors.orange[700]!,
        ),
        _buildStatItem(
          _totalEventos, // Variable conectada a DB
          "Eventos",
          "Eventos inscritos",
          Colors.purple[600]!,
        ),
      ],
    );
  }

  /// Tarjeta individual para una estadística
  Widget _buildStatItem(String value, String unit, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  /// Tarjeta para la "Información física"
  Widget _buildInfoCard() {
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
              "$_alturaCm cm",
              "Altura",
            ),
            _buildInfoItem(
              Icons.monitor_weight_outlined,
              "$_pesoKg kg",
              "Peso",
            ),
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
        title: Text(_objetivo), // Usa la variable
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

// ===================================================================
// ---         NUEVA PANTALLA PARA EDITAR EL PERFIL          ---
// ===================================================================

class EditProfileScreen extends StatefulWidget {
  final Map<String, String> currentUserData;

  const EditProfileScreen({super.key, required this.currentUserData});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos del formulario
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _descripcionController;
  late TextEditingController _alturaController;
  late TextEditingController _pesoController;
  late TextEditingController _objetivoController;

  @override
  void initState() {
    super.initState();
    // Inicializa los controladores con los datos actuales
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
  }

  @override
  void dispose() {
    // Limpia los controladores cuando el widget se destruye
    _nombreController.dispose();
    _emailController.dispose();
    _descripcionController.dispose();
    _alturaController.dispose();
    _pesoController.dispose();
    _objetivoController.dispose();
    super.dispose();
  }

  /// Guarda el formulario y regresa a la pantalla anterior
  void _onSave() {
    if (_formKey.currentState!.validate()) {
      // Crea un mapa con los nuevos datos
      final Map<String, String> updatedData = {
        'nombre': _nombreController.text,
        'email': _emailController.text,
        'descripcion': _descripcionController.text,
        'altura': _alturaController.text,
        'peso': _pesoController.text,
        'objetivo': _objetivoController.text,
      };

      // Regresa a la pantalla anterior (ProfileScreen) y pasa el mapa
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: kPrimaryGreen.withOpacity(0.8),
                  backgroundImage: (widget.currentUserData['avatarUrl']?.isNotEmpty ?? false)
                      ? NetworkImage(widget.currentUserData['avatarUrl']!)
                      : null,
                  child: Stack(
                    children: [
                      if ((widget.currentUserData['avatarUrl']?.isEmpty ?? true))
                        const Icon(Icons.person, size: 60, color: Colors.white),
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

  /// Widget de helper para crear un campo de texto estilizado
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
      validator: (value) => (value == null || value.isEmpty) ? 'Este campo no puede estar vacío' : null,
    );
  }
}
