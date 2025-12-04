import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String name;
  final String description;
  final String organizer;
  final DateTime date;
  final String location;
  final double price;
  final List<String> participants; // userIds participantes

  EventModel({
    required this.id,
    required this.name,
    required this.description,
    required this.organizer,
    required this.date,
    required this.location,
    required this.price,
    required this.participants,
  });

  factory EventModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      name: data['name'],
      description: data['description'],
      organizer: data['organizer'],
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'],
      price: data['price'].toDouble(),
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'organizer': organizer,
    'date': Timestamp.fromDate(date),
    'location': location,
    'price': price,
    'participants': participants,
  };
}
