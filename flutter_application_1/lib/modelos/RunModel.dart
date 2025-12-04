import 'package:cloud_firestore/cloud_firestore.dart';

class RunModel {
  final String id;
  final double distance;
  final int duration; // segundos
  final String pace;
  final double calories;
  final DateTime date;

  RunModel({
    required this.id,
    required this.distance,
    required this.duration,
    required this.pace,
    required this.calories,
    required this.date,
  });

  factory RunModel.fromDocument(DocumentSnapshot doc) {
    Map data = doc.data() as Map;

    return RunModel(
      id: doc.id,
      distance: (data["distance"] ?? 0).toDouble(),
      duration: data["duration"] ?? 0,
      pace: data["pace"] ?? "0:00",
      calories: (data["calories"] ?? 0).toDouble(),
      date: (data["date"] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "distance": distance,
      "duration": duration,
      "pace": pace,
      "calories": calories,
      "date": date,
    };
  }
}
