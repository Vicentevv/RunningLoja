import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final double goalDistance; // km objetivo
  final DateTime startDate;
  final DateTime endDate;
  final List<String> participants; // runners inscritos

  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.goalDistance,
    required this.startDate,
    required this.endDate,
    required this.participants,
  });

  factory ChallengeModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeModel(
      id: doc.id,
      title: data['title'],
      description: data['description'],
      goalDistance: (data['goalDistance']).toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'goalDistance': goalDistance,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'participants': participants,
  };
}
