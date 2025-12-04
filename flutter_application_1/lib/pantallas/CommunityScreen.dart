import 'package:flutter/material.dart';

// --- Definición de Colores (Copiados de tu HomeScreen.dart) ---
const Color kPrimaryGreen = Color(0xFF3A7D6E);
const Color kLightGreenBackground = Color(0xFFF0F5F3);
const Color kCardBackgroundColor = Colors.white;
const Color kPrimaryTextColor = Color(0xFF333333);
const Color kSecondaryTextColor = Color(0xFF666666);
const Color kAccentOrange = Color(0xFFE67E22);
const Color kAccentBlue = Color(0xFF3498DB);
const Color kAccentDarkGreen = Color(0xFF2E7D32);

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  // 0 para "Alimentar", 1 para "Grupos"
  int _selectedTabIndex = 0;

  // --- AÑADIDO: Índice para el BottomNavBar ---
  // 3 es el índice para "Comunidad"
  int _bottomNavIndex = 3;

  // --- AÑADIDO: Lógica de navegación del BottomNavBar ---
  void _onNavBarTap(int index) {
    setState(() {
      _bottomNavIndex = index;
    });

    // Lógica de navegación (asumiendo que tienes rutas nombradas)
    // Asegúrate de que las rutas coincidan con tu app.
    if (index == 0) {
      // Navegar a Inicio (HomeScreen)
      Navigator.pushReplacementNamed(
        context,
        '/HomeScreen',
      ); // O la ruta que uses
    }
    if (index == 1) {
      // Navegar a Eventos
      Navigator.pushReplacementNamed(context, '/EventosScreen');
    }
    if (index == 2) {
      // Navegar a Perfil
      Navigator.pushReplacementNamed(context, '/ProfileScreen');
    }
    if (index == 3) {
      Navigator.pushReplacementNamed(context, '/CommunityScreen');
    }
    if (index == 4) {
      Navigator.pushReplacementNamed(context, '/TrainingScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightGreenBackground,
      // Usamos un Stack para que el FAB se superponga al contenido
      body: Stack(
        children: [
          // Usamos SingleChildScrollView para que todo el contenido (incluido el header) se desplace
          SingleChildScrollView(
            child: Column(
              children: [
                _buildCommunityHeader(),
                _buildTabSwitcher(),
                // Espacio para el contenido del tab
                _buildTabContent(),
                const SizedBox(
                  height: 100,
                ), // Espacio extra para el FAB y BottomNav
              ],
            ),
          ),
          // Botón Flotante de "Añadir"
          Positioned(
            // --- MODIFICADO: Ajustado para que no choque con el BottomNav ---
            bottom: 80, // Sube el botón
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                // TODO: Lógica para crear un nuevo post
              },
              backgroundColor: kPrimaryGreen,
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            ),
          ),
        ],
      ),
      // --- AÑADIDO: Barra de Navegación Inferior ---
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// Construye el Header verde de la comunidad
  Widget _buildCommunityHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        60,
        24,
        24,
      ), // Ajustado para el status bar
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
          // Fila de Título y Búsqueda
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Comunidad',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white, size: 30),
                onPressed: () {
                  // TODO: Lógica de búsqueda
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Banner "¡Cada paso cuenta!"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '¡Cada paso cuenta! 👟',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el selector de pestañas "Alimentar" / "Grupos"
  Widget _buildTabSwitcher() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kCardBackgroundColor,
        borderRadius: BorderRadius.circular(30),
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
          _buildTabButton("Alimentar", 0),
          _buildTabButton("Grupos", 1),
        ],
      ),
    );
  }

  /// Botón individual para el selector de pestañas
  Widget _buildTabButton(String title, int index) {
    bool isActive = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? kPrimaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : kPrimaryGreen,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// Muestra el contenido de la pestaña seleccionada
  Widget _buildTabContent() {
    // Usamos un Column en lugar de ListView.builder porque la
    // pantalla completa ya es un SingleChildScrollView.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Mostrar contenido de "Alimentar"
          if (_selectedTabIndex == 0) ...[
            _buildPostInputCard(),
            _buildPostCard(
              initials: 'MG',
              avatarColor: Colors.teal,
              name: 'María González',
              level: 'Corredor Avanzado',
              time: '2 horas',
              text:
                  '¡Completa mi primera media maratón en Loja! 🏃‍♀️. Increíble experiencia corriendo por los hermosos paisajes de nuestra ciudad. ¡Gracias a todos por el apoyo!',
              likes: 24,
              comments: 8,
              hasImage: true,
            ),
            _buildPostCard(
              initials: 'DM',
              avatarColor: Colors.orange,
              name: 'Diego Morales',
              level: 'Corredor Intermedio',
              time: '4 horas',
              text:
                  'Rutina matutina en el Parque Jipiro ✨. Nada mejor que empezar el día con una buena carrera. ¿Quién se apunta mañana a las 6:00 AM?',
              likes: 15,
              comments: 12,
              hasImage: false,
            ),
            _buildPostCard(
              initials: 'CA',
              avatarColor: kPrimaryGreen,
              name: 'Ana Castillo',
              level: 'Principiante',
              time: '6 horas',
              text:
                  'Consejos para principiantes: Empezar poco a poco es la clave 💪. Después de 3 meses corriendo, por fin puedo hacer 5K sin parar. ¡Nunca se rindan!',
              likes: 31,
              comments: 18,
              hasImage: false,
            ),
            _buildPostCard(
              initials: 'CV',
              avatarColor: Colors.blueGrey,
              name: 'Carlos Vega',
              level: 'Maratonista',
              time: '8 horas',
              text:
                  'Entrenamiento de intervalos en la Universidad Nacional de Loja 🏃. 8x400m con 90s de descanso. ¡Preparándome para el próximo maratón!',
              likes: 19,
              comments: 6,
              hasImage: true,
            ),
          ],

          // Mostrar contenido de "Grupos"
          if (_selectedTabIndex == 1) ...[
            _buildGroupCard(
              icon: Icons.run_circle_outlined,
              iconColor: kAccentBlue,
              name: 'Corredores de Loja',
              members: '152 miembros',
            ),
            _buildGroupCard(
              icon: Icons.speed,
              iconColor: kAccentOrange,
              name: 'Principiantes 5K - Loja',
              members: '48 miembros',
            ),
            _buildGroupCard(
              icon: Icons.landscape,
              iconColor: kAccentDarkGreen,
              name: 'Trail Runners Jipiro',
              members: '81 miembros',
            ),
            _buildGroupCard(
              icon: Icons.flag_outlined,
              iconColor: Colors.redAccent,
              name: 'Maratón Team 2026',
              members: '22 miembros',
            ),
          ],
        ],
      ),
    );
  }

  /// Tarjeta para "Crear un nuevo post"
  Widget _buildPostInputCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: kLightGreenBackground,
            child: Text(
              'TÍME', // TODO: Reemplazar con el logo o iniciales del usuario
              style: TextStyle(
                color: kPrimaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '¿Qué tal tu entrenamiento hoy?',
              style: TextStyle(color: kSecondaryTextColor, fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(Icons.camera_alt_outlined, color: kSecondaryTextColor),
            onPressed: () {
              // TODO: Lógica para añadir foto
            },
          ),
        ],
      ),
    );
  }

  /// Tarjeta individual para un post del feed
  Widget _buildPostCard({
    required String initials,
    required Color avatarColor,
    required String name,
    required String level,
    required String time,
    required String text,
    required int likes,
    required int comments,
    bool hasImage = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del Post
          Row(
            children: [
              CircleAvatar(
                backgroundColor: avatarColor.withOpacity(0.2),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: avatarColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: kPrimaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$level • $time',
                      style: TextStyle(
                        color: kSecondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.more_horiz, color: kSecondaryTextColor),
                onPressed: () {
                  // TODO: Lógica para opciones de post
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Contenido del Post
          Text(
            text,
            style: TextStyle(
              color: kPrimaryTextColor,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          // Imagen (si existe)
          if (hasImage)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                // TODO: Reemplazar este placeholder con tu Image.asset o Image.network
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    image: DecorationImage(
                      // Estoy usando un placeholder de red, reemplaza con tu imagen
                      image: NetworkImage(
                        'https://picsum.photos/seed/${name.hashCode}/600/400',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Footer (Likes, Comentarios, Compartir)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite, color: Colors.red, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    '$likes',
                    style: TextStyle(
                      color: kSecondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Icon(
                    Icons.chat_bubble_outline,
                    color: kSecondaryTextColor,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$comments',
                    style: TextStyle(
                      color: kSecondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Icon(Icons.share_outlined, color: kSecondaryTextColor, size: 22),
            ],
          ),
        ],
      ),
    );
  }

  /// --- Pestaña de Grupos (Generada) ---

  /// Tarjeta individual para un Grupo
  Widget _buildGroupCard({
    required IconData icon,
    required Color iconColor,
    required String name,
    required String members,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: iconColor, size: 30),
        ),
        title: Text(
          name,
          style: TextStyle(
            color: kPrimaryTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          members,
          style: TextStyle(color: kSecondaryTextColor, fontSize: 14),
        ),
        trailing: OutlinedButton(
          onPressed: () {
            // TODO: Lógica para unirse al grupo
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: kPrimaryGreen,
            side: BorderSide(color: kPrimaryGreen, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('Unirse'),
        ),
      ),
    );
  }

  /// Barra de Navegación Inferior
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _bottomNavIndex,
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
              color: _bottomNavIndex == 2
                  ? kPrimaryGreen.withOpacity(0.1)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              color: _bottomNavIndex == 2 ? kPrimaryGreen : kSecondaryTextColor,
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
          icon: Icon(Icons.play_arrow), // Asumiendo que esta es la 5ta pestaña
          activeIcon: Icon(Icons.play_arrow_outlined),
          label: 'Entrenar',
        ),
      ],
    );
  }
}
