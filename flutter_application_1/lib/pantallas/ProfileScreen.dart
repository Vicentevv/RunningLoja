import 'package:flutter/material.dart';

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
         '/EventosScreen': (context) => const PlaceholderScreen(title: 'Eventos'),
         '/CommunityScreen': (context) => const PlaceholderScreen(title: 'Comunidad'),
         '/TrainingScreen': (context) => const PlaceholderScreen(title: 'Entrenar'),
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
  // Índice actual para la barra de navegación inferior
  int _selectedIndex = 2; // 2 corresponde a "Perfil"

  // --- DATOS DEL PERFIL (AHORA SON VARIABLES DE ESTADO) ---
  String _nombre = "Carlos Mendoza";
  String _email = "carlos.mendoza@email.com";
  String _descripcion = "Abierto (20-35 años) • Intermedio";
  String _avatarUrl =
      'https://th.bing.com/th/id/R.396fe9612612f1114139cfd84fffc2ab?rik=ZftYAC4zPrwlhg&pid=ImgRaw&r=0';
  String _alturaCm = "175";
  String _pesoKg = "70";
  String _objetivo = "Completar mi primer maratón en 2024";
  // ---

  /// NAVEGA A LA PANTALLA DE EDICIÓN Y ESPERA LOS RESULTADOS
  void _navigateToEditProfile() async {
    final Map<String, String> currentUserData = {
      'nombre': _nombre,
      'email': _email,
      'descripcion': _descripcion,
      'altura': _alturaCm,
      'peso': _pesoKg,
      'objetivo': _objetivo,
      'avatarUrl': _avatarUrl,
    };

    // Navega a la pantalla de edición y espera a que regrese (con Navigator.pop)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(currentUserData: currentUserData),
      ),
    );

    // Si 'result' no es nulo, significa que el usuario guardó los cambios.
    if (result != null && result is Map<String, String>) {
      setState(() {
        _nombre = result['nombre'] ?? _nombre;
        _email = result['email'] ?? _email;
        _descripcion = result['descripcion'] ?? _descripcion;
        _alturaCm = result['altura'] ?? _alturaCm;
        _pesoKg = result['peso'] ?? _pesoKg;
        _objetivo = result['objetivo'] ?? _objetivo;
        // _avatarUrl = result['avatarUrl'] ?? _avatarUrl; // (La URL no se edita en este form)
      });
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
            icon: Icon(Icons.watch_later_outlined), // ICONO CORREGIDO
            activeIcon: Icon(Icons.watch_later), // ICONO CORREGIDO
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
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
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
                backgroundImage: NetworkImage(_avatarUrl), // Usa la variable
                backgroundColor: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(width: 15),
              Expanded( // Añadido Expanded para evitar overflow
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nombre, // Usa la variable
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email, // Usa la variable
                      style: TextStyle(color: Colors.white.withOpacity(0.9)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _descripcion, // Usa la variable
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
        _buildStatItem("156,8", "kilómetros", "Distancia total", Colors.blue[700]!),
        _buildStatItem("24", "Carreras", "Carreras completadas", Colors.green[600]!),
        _buildStatItem("5:45", "min/km", "Ritmo", Colors.orange[700]!),
        _buildStatItem("3", "Eventos", "Eventos", Colors.purple[600]!),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
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
            _buildInfoItem(Icons.height, "$_alturaCm cm", "Altura"), // Usa variable
            _buildInfoItem(Icons.monitor_weight_outlined, "$_pesoKg kg", "Peso"), // Usa variable
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
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
      IconData icon, String label, Color bgColor, Color iconColor) {
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
    // (Sin cambios)
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
          _buildSettingsItem(
            Icons.lock_outline,
            "Privacidad",
            Colors.blue,
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildSettingsItem(
            Icons.logout,
            "Cerrar sesión",
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, Color iconColor) {
    // (Sin cambios)
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        // Acción para este ítem de configuración
      },
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
    _nombreController = TextEditingController(text: widget.currentUserData['nombre']);
    _emailController = TextEditingController(text: widget.currentUserData['email']);
    _descripcionController = TextEditingController(text: widget.currentUserData['descripcion']);
    _alturaController = TextEditingController(text: widget.currentUserData['altura']);
    _pesoController = TextEditingController(text: widget.currentUserData['peso']);
    _objetivoController = TextEditingController(text: widget.currentUserData['objetivo']);
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
          style: TextStyle(color: kPrimaryTextColor, fontWeight: FontWeight.bold),
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
          )
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
                  backgroundImage: NetworkImage(widget.currentUserData['avatarUrl']!),
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: kPrimaryGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2)
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 20),
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
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _descripcionController,
                label: 'Descripción (Categoría, Nivel)',
                icon: Icons.info_outline,
              ),
              const SizedBox(height: 24),
              Text(
                'Información física',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kSecondaryTextColor),
        prefixIcon: Icon(icon),
        suffixText: suffixText,
        suffixStyle: const TextStyle(color: kSecondaryTextColor),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo no puede estar vacío';
        }
        return null;
      },
    );
  }
}