import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/pantallas/CreatePostModal.dart';
import '../modelos/PostModel.dart';

// --- Colores ---
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
  int _selectedTabIndex = 0;
  int _bottomNavIndex = 3;

  void _onNavBarTap(int index) {
    setState(() {
      _bottomNavIndex = index;
    });

    if (index == 0) Navigator.pushReplacementNamed(context, '/HomeScreen');
    if (index == 1) Navigator.pushReplacementNamed(context, '/EventosScreen');
    if (index == 2) Navigator.pushReplacementNamed(context, '/ProfileScreen');
    if (index == 3) Navigator.pushReplacementNamed(context, '/CommunityScreen');
    if (index == 4) Navigator.pushReplacementNamed(context, '/TrainingScreen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightGreenBackground,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildCommunityHeader(),
                _buildTabContent(),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // FAB CORREGIDO
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (_) => const CreatePostModal(),
                );
              },
              backgroundColor: kPrimaryGreen,
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // HEADER
  Widget _buildCommunityHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
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
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
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

  // BOTONES TABS
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

  // CONTENIDO
  Widget _buildTabContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),

          Row(
            children: [
              _buildTabButton("Alimentar", 0),
              const SizedBox(width: 12),
              _buildTabButton("Grupos", 1),
            ],
          ),

          const SizedBox(height: 20),

          if (_selectedTabIndex == 0)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("posts")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text(
                    "Aún no hay publicaciones.",
                    style: TextStyle(color: Colors.grey),
                  );
                }

                final docs = snapshot.data!.docs;

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final post = PostModel.fromJson(data);

                    return _buildPostCard(
                      initials: post.userName.isNotEmpty
                          ? post.userName.substring(0, 1).toUpperCase()
                          : "?",
                      avatarColor: Colors.teal,
                      name: post.userName,
                      level: post.userLevel,
                      time: "hace poco",
                      text: post.description,
                      likes: post.likesCount ?? 0,
                      comments: 0, // 🟢 commentsCount corregido
                      imageBase64: post.imageBase64,
                    );
                  }).toList(),
                );
              },
            ),

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
          ],
        ],
      ),
    );
  }

  // POST CARD
  Widget _buildPostCard({
    required String initials,
    required Color avatarColor,
    required String name,
    required String level,
    required String time,
    required String text,
    required int likes,
    required int comments,
    required String? imageBase64,
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
                      style: const TextStyle(
                        color: kPrimaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "$level • $time",
                      style: const TextStyle(
                        color: kSecondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: kSecondaryTextColor),
                onPressed: () {},
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            text,
            style: const TextStyle(
              color: kPrimaryTextColor,
              fontSize: 16,
              height: 1.4,
            ),
          ),

          if (imageBase64 != null && imageBase64.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  base64Decode(imageBase64),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    "$likes",
                    style: const TextStyle(
                      color: kSecondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 24),
                  const Icon(
                    Icons.chat_bubble_outline,
                    color: kSecondaryTextColor,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "$comments",
                    style: const TextStyle(
                      color: kSecondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.share_outlined,
                color: kSecondaryTextColor,
                size: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TARJETA DE GRUPO
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
          style: const TextStyle(
            color: kPrimaryTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          members,
          style: const TextStyle(color: kSecondaryTextColor, fontSize: 14),
        ),
        trailing: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: kPrimaryGreen,
            side: const BorderSide(color: kPrimaryGreen, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('Unirse'),
        ),
      ),
    );
  }

  // NAV BAR
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _bottomNavIndex,
      onTap: _onNavBarTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: kCardBackgroundColor,
      selectedItemColor: kPrimaryGreen,
      unselectedItemColor: kSecondaryTextColor,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Eventos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Comunidad',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.play_arrow),
          activeIcon: Icon(Icons.play_arrow_outlined),
          label: 'Entrenar',
        ),
      ],
    );
  }
}
