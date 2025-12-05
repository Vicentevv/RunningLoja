import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ============================================================
  /// REGISTRO DE USUARIO (Auth + Firestore)
  /// ============================================================
  Future<String?> registerUser({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      // Registrar en FirebaseAuth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // Guardar datos iniciales en Firestore
      await _db.collection("users").doc(uid).set({
        "fullName": fullName,
        "email": email,
        "photoUrl": "",
        "createdAt": FieldValue.serverTimestamp(),
        // Datos físicos
        "height": 0,
        "weight": 0,
        // Estadísticas globales
        "totalDistance": 0,
        "totalRuns": 0,
        "averagePace": "0:00",
        "streakDays": 0,
        // Objetivos
        "currentGoal": "",
        "myEventIds": [],
        // Entrenamientos
        "role": "runner", // Por defecto
      });

      return null; // Éxito
    } on FirebaseAuthException catch (e) {
      return _handleAuthErrors(e.code);
    } catch (e) {
      return "Error inesperado: $e";
    }
  }

  /// ============================================================
  /// INICIAR SESIÓN
  /// ============================================================
  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // éxito
    } on FirebaseAuthException catch (e) {
      return _handleAuthErrors(e.code);
    } catch (e) {
      return "Error inesperado: $e";
    }
  }

  /// ============================================================
  /// 🔥 NUEVO: ENVIAR CORREO DE RECUPERACIÓN
  /// ============================================================
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Éxito
    } on FirebaseAuthException catch (e) {
      return _handleAuthErrors(e.code);
    } catch (e) {
      return "Error al enviar correo: $e";
    }
  }

  /// ============================================================
  /// CERRAR SESIÓN
  /// ============================================================
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// ============================================================
  /// OBTENER UID ACTUAL
  /// ============================================================
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// ============================================================
  /// OBTENER DATOS DE USUARIO (SNAPSHOT)
  /// ============================================================
  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserData() async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return null;

      DocumentSnapshot<Map<String, dynamic>> snapshot = await _db
          .collection("users")
          .doc(uid)
          .get();

      return snapshot;
    } catch (e) {
      return null;
    }
  }

  /// ============================================================
  /// MANEJO DE ERRORES DE AUTH
  /// ============================================================
  String _handleAuthErrors(String code) {
    switch (code) {
      case "email-already-in-use":
        return "El correo ya está registrado.";
      case "invalid-email":
        return "El correo no es válido.";
      case "weak-password":
        return "La contraseña es demasiado débil.";
      case "user-not-found":
        return "No existe un usuario con ese correo.";
      case "wrong-password":
        return "La contraseña es incorrecta.";
      case "too-many-requests":
        return "Demasiados intentos. Intenta más tarde.";
      case "auth/user-not-found": // Código específico a veces retornado
        return "No encontramos una cuenta con este correo.";
      default:
        return "Error: $code";
    }
  }
}
