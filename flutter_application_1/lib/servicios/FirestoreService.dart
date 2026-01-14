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

  /// 🔥 NUEVO: Cambiar el estado de verificación de un usuario
  Future<void> updateVerificationStatus(String uid, bool status) async {
    try {
      await _db.collection("users").doc(uid).update({"isVerified": status});
    } catch (e) {
      throw Exception("Error al actualizar verificación: $e");
    }
  }

  // Lista de usuarios QUE EXCLUYE ADMINISTRADORES
  Stream<List<UserModel>> getAllUsersStream() {
    return _db.collection("users").snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromDocument(doc))
          .where(
            (user) => user.role != 'admin',
          ) // FILTRO: Solo devuelve si el rol NO es admin
          .toList();
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

  // ============================================================
  // 💬 COMENTARIOS
  // ============================================================

  /// Agregar un comentario a un post
  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String text,
    bool isVerified = false,
  }) async {
    try {
      final commentId = _db
          .collection("posts")
          .doc(postId)
          .collection("comments")
          .doc()
          .id;

      await _db
          .collection("posts")
          .doc(postId)
          .collection("comments")
          .doc(commentId)
          .set({
            "id": commentId,
            "userId": userId,
            "userName": userName,
            "text": text,
            "createdAt": DateTime.now().toIso8601String(),
            "isVerified": isVerified,
          });

      // Incrementar conteo de comentarios
      await _db.collection("posts").doc(postId).update({
        "commentsCount": FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception("Error al agregar comentario: $e");
    }
  }

  /// Obtener comentarios de un post
  Stream<QuerySnapshot> getComments(String postId) {
    return _db
        .collection("posts")
        .doc(postId)
        .collection("comments")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  /// Eliminar un comentario
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    try {
      await _db
          .collection("posts")
          .doc(postId)
          .collection("comments")
          .doc(commentId)
          .delete();

      // Decrementar conteo de comentarios
      await _db.collection("posts").doc(postId).update({
        "commentsCount": FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception("Error al eliminar comentario: $e");
    }
  }

  // ============================================================
  // ❤️ LIKES
  // ============================================================

  /// Agregar un like a un post
  Future<void> addLike(String postId, String userId) async {
    try {
      await _db
          .collection("posts")
          .doc(postId)
          .collection("likes")
          .doc(userId)
          .set({
            "userId": userId,
            "createdAt": DateTime.now().toIso8601String(),
          });

      // Incrementar conteo de likes
      await _db.collection("posts").doc(postId).update({
        "likesCount": FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception("Error al agregar like: $e");
    }
  }

  /// Remover un like de un post
  Future<void> removeLike(String postId, String userId) async {
    try {
      await _db
          .collection("posts")
          .doc(postId)
          .collection("likes")
          .doc(userId)
          .delete();

      // Decrementar conteo de likes
      await _db.collection("posts").doc(postId).update({
        "likesCount": FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception("Error al remover like: $e");
    }
  }

  /// Obtener los likes de un post
  Stream<QuerySnapshot> getLikes(String postId) {
    return _db.collection("posts").doc(postId).collection("likes").snapshots();
  }

  /// Verificar si el usuario actual le dio like al post
  Future<bool> hasUserLikedPost(String postId, String userId) async {
    try {
      final likeDoc = await _db
          .collection("posts")
          .doc(postId)
          .collection("likes")
          .doc(userId)
          .get();

      return likeDoc.exists;
    } catch (e) {
      throw Exception("Error al verificar like: $e");
    }
  }

  // ============================================================
  // ❤️ LIKES EN COMENTARIOS
  // ============================================================

  /// Agregar un like a un comentario
  Future<void> addCommentLike(
    String postId,
    String commentId,
    String userId,
  ) async {
    try {
      await _db
          .collection("posts")
          .doc(postId)
          .collection("comments")
          .doc(commentId)
          .collection("likes")
          .doc(userId)
          .set({
            "userId": userId,
            "createdAt": DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw Exception("Error al agregar like al comentario: $e");
    }
  }

  /// Remover un like de un comentario
  Future<void> removeCommentLike(
    String postId,
    String commentId,
    String userId,
  ) async {
    try {
      await _db
          .collection("posts")
          .doc(postId)
          .collection("comments")
          .doc(commentId)
          .collection("likes")
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception("Error al remover like del comentario: $e");
    }
  }

  /// Verificar si el usuario actual le dio like al comentario
  Future<bool> hasCommentLike(
    String postId,
    String commentId,
    String userId,
  ) async {
    try {
      final likeDoc = await _db
          .collection("posts")
          .doc(postId)
          .collection("comments")
          .doc(commentId)
          .collection("likes")
          .doc(userId)
          .get();

      return likeDoc.exists;
    } catch (e) {
      throw Exception("Error al verificar like del comentario: $e");
    }
  }

  /// Obtener los likes de un comentario
  Stream<QuerySnapshot> getCommentLikes(String postId, String commentId) {
    return _db
        .collection("posts")
        .doc(postId)
        .collection("comments")
        .doc(commentId)
        .collection("likes")
        .snapshots();
  }
}
