import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/RunModel.dart';

class RunService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ============================================================
  /// Agregar nueva carrera a un usuario
  /// ============================================================
  Future<void> addRun(String uid, RunModel run) async {
    try {
      await _db
          .collection("users")
          .doc(uid)
          .collection("runs")
          .add(run.toJson());
    } catch (e) {
      throw Exception("Error al guardar carrera: $e");
    }
  }

  /// ============================================================
  /// Obtener lista de carreras del usuario (stream tiempo real)
  /// ============================================================
  Stream<List<RunModel>> getRuns(String uid) {
    return _db
        .collection("users")
        .doc(uid)
        .collection("runs")
        .orderBy("date", descending: true)
        .snapshots()
        .map(
          (query) =>
              query.docs.map((doc) => RunModel.fromDocument(doc)).toList(),
        );
  }

  /// ============================================================
  /// Eliminar carrera
  /// ============================================================
  Future<void> deleteRun(String uid, String runId) async {
    try {
      await _db
          .collection("users")
          .doc(uid)
          .collection("runs")
          .doc(runId)
          .delete();
    } catch (e) {
      throw Exception("Error al eliminar carrera: $e");
    }
  }
}
