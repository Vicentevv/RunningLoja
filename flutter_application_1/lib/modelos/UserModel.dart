import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  String fullName;
  String email;
  String avatarBase64; // ⬅️ NUEVO
  DateTime createdAt;

  double totalDistance;
  int totalRuns;
  String averagePace;
  int streakDays;

  String currentGoal;
  List<String> myEventIds;

  double height;
  double weight;
  String role;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.avatarBase64, // ⬅️ nuevo
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

  Map<String, dynamic> toJson() {
    return {
      "uid": uid,
      "fullName": fullName,
      "email": email,
      "avatarBase64": avatarBase64, // ⬅️ nuevo
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json["uid"],
      fullName: json["fullName"],
      email: json["email"],
      avatarBase64: json["avatarBase64"] ?? "", // ⬅️ nuevo
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

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: data["uid"],
      fullName: data["fullName"],
      email: data["email"],
      avatarBase64: data["avatarBase64"] ?? "", // ⬅️ nuevo
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
