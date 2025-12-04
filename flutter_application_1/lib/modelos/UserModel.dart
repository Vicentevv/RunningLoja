import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  String fullName;
  String email;
  String photoUrl;
  DateTime createdAt;

  double totalDistance; // km
  int totalRuns;
  String averagePace; // Ej: 5:30 min/km
  int streakDays; // racha de días seguidos

  String currentGoal; // objetivo actual (texto)
  List<String> myEventIds;

  double height; // estatura
  double weight; // peso
  String role; // "runner", "admin", etc.

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.photoUrl,
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
  });

  //Convertir a JSON para guardar en Firestore
  Map<String, dynamic> toJson() {
    return {
      "uid": uid,
      "fullName": fullName,
      "email": email,
      "photoUrl": photoUrl,
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
    };
  }

  //Leer modelo desde JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json["uid"],
      fullName: json["fullName"],
      email: json["email"],
      photoUrl: json["photoUrl"],
      createdAt: DateTime.parse(json["createdAt"]),
      totalDistance: json["totalDistance"].toDouble(),
      totalRuns: json["totalRuns"],
      averagePace: json["averagePace"],
      streakDays: json["streakDays"],
      currentGoal: json["currentGoal"],
      myEventIds: List<String>.from(json["myEventIds"]),
      height: json["height"].toDouble(),
      weight: json["weight"].toDouble(),
      role: json["role"],
    );
  }

  /// 📄 Leer modelo desde Firestore (DocumentSnapshot)
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: data["uid"],
      fullName: data["fullName"],
      email: data["email"],
      photoUrl: data["photoUrl"],
      createdAt: DateTime.parse(data["createdAt"]),
      totalDistance: data["totalDistance"].toDouble(),
      totalRuns: data["totalRuns"],
      averagePace: data["averagePace"],
      streakDays: data["streakDays"],
      currentGoal: data["currentGoal"],
      myEventIds: List<String>.from(data["myEventIds"]),
      height: data["height"].toDouble(),
      weight: data["weight"].toDouble(),
      role: data["role"],
    );
  }
}
