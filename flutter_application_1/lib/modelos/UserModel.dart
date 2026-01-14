import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  String fullName;
  String email;
  String avatarBase64; // Imagen en Base64
  DateTime createdAt;

  // Estadísticas de Running
  double totalDistance;
  int totalRuns;
  String averagePace;
  int streakDays;

  // Objetivos y Eventos
  String currentGoal;
  List<String> myEventIds;

  // Datos Físicos
  double height;
  double weight;

  // Rol y Permisos
  String role;
  bool isVerified; // <-- Permiso para crear carreras (Solo editable por admin)

  // --- NUEVOS CAMPOS (Solicitados en Editar Perfil) ---
  String phone;
  DateTime birthDate;
  String gender; // Ej: "Masculino", "Femenino"
  String category; // Ej: "Abierta (26-35 años)"
  String experience; // Ej: "Intermedio"

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.avatarBase64,
    required this.createdAt,
    required this.totalDistance,
    required this.totalRuns,
    required this.averagePace,
    required this.streakDays,
    required this.currentGoal,
    required this.myEventIds,
    required this.height,
    required this.weight,
    required this.role,
    required this.isVerified,
    required this.phone,
    required this.birthDate,
    required this.gender,
    required this.category,
    required this.experience,
  });

  // ------ TO JSON (Guardar en Firestore) ------
  Map<String, dynamic> toJson() {
    return {
      "uid": uid,
      "fullName": fullName,
      "email": email,
      "avatarBase64": avatarBase64,
      "createdAt": createdAt.toIso8601String(),
      "totalDistance": totalDistance,
      "totalRuns": totalRuns,
      "averagePace": averagePace,
      "streakDays": streakDays,
      "currentGoal": currentGoal,
      "myEventIds": myEventIds,
      "height": height,
      "weight": weight,
      "role": role,
      "isVerified": isVerified, // Persistimos el estado de verificación
      "phone": phone,
      "birthDate": birthDate.toIso8601String(),
      "gender": gender,
      "category": category,
      "experience": experience,
    };
  }

  // ------ FROM JSON (Leer mapa simple) ------
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json["uid"] ?? "",
      fullName: json["fullName"] ?? "",
      email: json["email"] ?? "",
      avatarBase64: json["avatarBase64"] ?? "",
      createdAt: json["createdAt"] != null
          ? DateTime.parse(json["createdAt"])
          : DateTime.now(),
      totalDistance: (json["totalDistance"] as num? ?? 0).toDouble(),
      totalRuns: json["totalRuns"] ?? 0,
      averagePace: json["averagePace"] ?? "0:00",
      streakDays: json["streakDays"] ?? 0,
      currentGoal: json["currentGoal"] ?? "",
      myEventIds: json["myEventIds"] != null
          ? List<String>.from(json["myEventIds"])
          : [],
      height: (json["height"] as num? ?? 0).toDouble(),
      weight: (json["weight"] as num? ?? 0).toDouble(),
      role: json["role"] ?? "user",
      isVerified:
          json["isVerified"] ??
          false, // Garantizamos que por defecto sea false si no existe

      phone: json["phone"] ?? "",
      birthDate: json["birthDate"] != null
          ? DateTime.parse(json["birthDate"])
          : DateTime(2000, 1, 1),
      gender: json["gender"] ?? "",
      category: json["category"] ?? "",
      experience: json["experience"] ?? "",
    );
  }

  // ------ FROM DOCUMENT (Leer desde Firestore) ------
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserModel(
      uid: data["uid"] ?? doc.id,
      fullName: data["fullName"] ?? "",
      email: data["email"] ?? "",
      avatarBase64: data["avatarBase64"] ?? "",
      createdAt: data["createdAt"] != null
          ? DateTime.parse(data["createdAt"])
          : DateTime.now(),
      totalDistance: (data["totalDistance"] as num? ?? 0).toDouble(),
      totalRuns: data["totalRuns"] ?? 0,
      averagePace: data["averagePace"] ?? "0:00",
      streakDays: data["streakDays"] ?? 0,
      currentGoal: data["currentGoal"] ?? "",
      myEventIds: data["myEventIds"] != null
          ? List<String>.from(data["myEventIds"])
          : [],
      height: (data["height"] as num? ?? 0).toDouble(),
      weight: (data["weight"] as num? ?? 0).toDouble(),
      role: data["role"] ?? "user",
      isVerified:
          data["isVerified"] ??
          false, // Seguridad: si el campo no existe en el doc, es false

      phone: data["phone"] ?? "",
      birthDate:
          (data["birthDate"] is String &&
              (data["birthDate"] as String).isNotEmpty)
          ? DateTime.parse(data["birthDate"])
          : DateTime(2000, 1, 1),
      gender: data["gender"] ?? "",
      category: data["category"] ?? "",
      experience: data["experience"] ?? "",
    );
  }
}
