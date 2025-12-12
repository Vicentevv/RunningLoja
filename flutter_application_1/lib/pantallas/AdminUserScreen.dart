import 'package:flutter/material.dart';
import 'package:flutter_application_1/modelos/UserModel.dart';
import 'package:flutter_application_1/servicios/FirestoreService.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Usuarios"),
        backgroundColor: const Color(0xFF4C7C63), // Tu color primario
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.getAllUsersStream(),
        builder: (context, snapshot) {
          // 1. Cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // 3. Sin datos
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay usuarios registrados."));
          }

          final users = snapshot.data!;

          return Column(
            children: [
              // Encabezado con contador
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                width: double.infinity,
                child: Text(
                  "Total usuarios registrados: ${users.length}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4C7C63),
                  ),
                ),
              ),

              // Lista de Usuarios
              Expanded(
                child: ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      title: Text(
                        user.fullName.isNotEmpty ? user.fullName : "Sin nombre",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.email),
                          Text(
                            "Rol: ${user.role}",
                            style: TextStyle(
                              color: user.role == 'admin'
                                  ? Colors.red
                                  : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          _confirmDelete(context, firestoreService, user);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    FirestoreService service,
    UserModel user,
  ) {
    if (user.role == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No puedes eliminar a un administrador.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar Usuario"),
        content: Text(
          "¿Estás seguro de que quieres eliminar a ${user.fullName}? Esta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Cerrar diálogo
              try {
                await service.deleteUserDocument(user.uid);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Usuario eliminado correctamente"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }
}
