import 'package:flutter/material.dart';
import '../modelos/UserModel.dart';
import '../servicios/FirestoreService.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF4C7C63);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Gestión de Usuarios"),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                icon: Icon(Icons.person_remove_outlined),
                text: "No Verificados",
              ),
              Tab(icon: Icon(Icons.verified_user), text: "Verificados"),
            ],
          ),
        ),
        body: Column(
          children: [
            // BARRA DE BÚSQUEDA
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Buscar por nombre o correo...",
                  prefixIcon: const Icon(Icons.search, color: primaryColor),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = "";
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),

            // LISTADO DINÁMICO
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: _firestoreService.getAllUsersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("No hay usuarios registrados."),
                    );
                  }

                  final allFilteredUsers = snapshot.data!.where((u) {
                    final name = u.fullName.toLowerCase();
                    final email = u.email.toLowerCase();
                    return name.contains(_searchQuery) ||
                        email.contains(_searchQuery);
                  }).toList();

                  final unverifiedUsers = allFilteredUsers
                      .where((u) => !u.isVerified)
                      .toList();
                  final verifiedUsers = allFilteredUsers
                      .where((u) => u.isVerified)
                      .toList();

                  return TabBarView(
                    children: [
                      _buildUserList(unverifiedUsers, primaryColor, false),
                      _buildUserList(verifiedUsers, primaryColor, true),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(
    List<UserModel> users,
    Color primaryColor,
    bool isViewingVerified,
  ) {
    if (users.isEmpty) {
      return const Center(child: Text("Lista vacía"));
    }

    return ListView.separated(
      itemCount: users.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Text(user.fullName.isNotEmpty ? user.fullName[0] : "?"),
          ),
          title: Text(user.fullName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.email, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              _buildStatusBadge(user.isVerified),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // BOTÓN PRINCIPAL DE ACCIÓN PARA VERIFICAR/DESVERIFICAR
              ElevatedButton(
                onPressed: () => _toggleVerification(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: user.isVerified
                      ? Colors.grey[200]
                      : Colors.green[700],
                  foregroundColor: user.isVerified
                      ? Colors.black87
                      : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  user.isVerified ? "Quitar" : "Verificar",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _confirmDelete(context, user),
              ),
            ],
          ),
        );
      },
    );
  }

  // MÉTODO PARA CAMBIAR EL ESTADO
  Future<void> _toggleVerification(UserModel user) async {
    try {
      final bool newStatus = !user.isVerified;
      await _firestoreService.updateVerificationStatus(user.uid, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? "Usuario verificado" : "Verificación removida",
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildStatusBadge(bool verified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: verified
            ? Colors.blue.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        verified ? "USUARIO VERIFICADO" : "USUARIO NO VERIFICADO",
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: verified ? Colors.blue : Colors.red[800],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar"),
        content: Text("¿Borrar a ${user.fullName}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestoreService.deleteUserDocument(user.uid);
            },
            child: const Text("Sí, eliminar"),
          ),
        ],
      ),
    );
  }
}
