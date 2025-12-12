import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/UserModel.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ============================================================
  /// Guardar un usuario nuevo en Firestore
  /// Esto se ejecuta inmediatamente después del registro
  /// ============================================================
  Future<void> createUser(UserModel user) async {
    try {
      await _db.collection("users").doc(user.uid).set(user.toJson());
    } catch (e) {
      throw Exception("Error al crear usuario en Firestore: $e");
    }
  }

  /// ============================================================
  /// Obtener datos del usuario
  /// ============================================================
  Future<UserModel?> getUserById(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection("users").doc(uid).get();

      if (!doc.exists) return null;

      return UserModel.fromDocument(doc);
    } catch (e) {
      throw Exception("Error al obtener usuario: $e");
    }
  }

  /// ============================================================
  /// Actualizar datos del usuario (nombre, foto, etc.)
  /// ============================================================
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection("users").doc(uid).update(data);
    } catch (e) {
      throw Exception("Error al actualizar usuario: $e");
    }
  }

  /// ============================================================
  /// Actualizar estadísticas globales del usuario
  /// ============================================================
  Future<void> updateGlobalStats({
    required String uid,
    required double distance,
    required String pace,
    bool addRun = true,
  }) async {
    try {
      DocumentReference userRef = _db.collection("users").doc(uid);

      await _db.runTransaction((transaction) async {
        DocumentSnapshot snap = await transaction.get(userRef);
        if (!snap.exists) return;

        double prevDistance = (snap["totalDistance"] ?? 0).toDouble();
        int prevRuns = snap["totalRuns"] ?? 0;
        int streak = snap["streakDays"] ?? 0;

        transaction.update(userRef, {
          "totalDistance": prevDistance + distance,
          "totalRuns": addRun ? prevRuns + 1 : prevRuns,
          "averagePace": pace,
          "streakDays": streak + 1,
        });
      });
    } catch (e) {
      throw Exception("Error al actualizar estadísticas: $e");
    }
  }

  /// ============================================================
  /// Actualizar datos físicos del usuario (altura, peso)
  /// ============================================================
  Future<void> updatePhysicalData({
    required String uid,
    double? height,
    double? weight,
  }) async {
    try {
      await _db.collection("users").doc(uid).update({
        if (height != null) "height": height,
        if (weight != null) "weight": weight,
      });
    } catch (e) {
      throw Exception("Error al actualizar datos físicos: $e");
    }
  }

  /// ============================================================
  /// Añadir evento a la lista del usuario
  /// ============================================================
  Future<void> addEventToUser(String uid, String eventId) async {
    try {
      await _db.collection("users").doc(uid).update({
        "myEventIds": FieldValue.arrayUnion([eventId]),
      });
    } catch (e) {
      throw Exception("Error al agregar evento al usuario: $e");
    }
  }

  /// ============================================================
  /// Remover evento del usuario
  /// ============================================================
  Future<void> removeEventFromUser(String uid, String eventId) async {
    try {
      await _db.collection("users").doc(uid).update({
        "myEventIds": FieldValue.arrayRemove([eventId]),
      });
    } catch (e) {
      throw Exception("Error al eliminar evento: $e");
    }
  }

  // ============================================================
  // 🔥 ZONA ADMIN: GESTIÓN DE USUARIOS
  // ============================================================

  /// Obtener todos los usuarios (para la lista de gestión)
  Stream<List<UserModel>> getAllUsersStream() {
    return _db.collection("users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
    });
  }

  /// Eliminar un usuario de la base de datos
  /// Nota: Esto borra sus datos de Firestore. Para borrar la cuenta de Auth
  /// completamente se requiere una Cloud Function o hacerlo desde consola,
  /// pero esto es suficiente para que la app deje de reconocerlo.
  Future<void> deleteUserDocument(String uid) async {
    try {
      await _db.collection("users").doc(uid).delete();
    } catch (e) {
      throw Exception("Error al eliminar usuario: $e");
    }
  }
}
