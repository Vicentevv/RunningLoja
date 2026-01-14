import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RunModel {
  final String id;
  final double distanceKm;
  final int durationSeconds;
  final double paceMinPerKm;
  final double calories;
  final DateTime date;
  final List<LatLng> routePoints;

  RunModel({
    required this.id,
    required this.distanceKm,
    required this.durationSeconds,
    required this.paceMinPerKm,
    required this.calories,
    required this.date,
    this.routePoints = const [],
  });

  factory RunModel.fromDocument(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    
    // Decodificar puntos si existen
    List<LatLng> points = [];
    if (data['points'] != null) {
      // Intentar parsear la lista de mapas {lat, lng}
      try {
        points = (data['points'] as List).map((p) {
          return LatLng(
            (p['lat'] as num).toDouble(), 
            (p['lng'] as num).toDouble()
          );
        }).toList();
      } catch (e) {
        print("Error parsing route points: $e");
      }
    }

    return RunModel(
      id: doc.id,
      // Soporte retroactivo para campos antiguos cammelCase o snake_case
      distanceKm: (data["distance_km"] ?? data["distance"] ?? 0).toDouble(),
      durationSeconds: (data["duration_seconds"] ?? data["duration"] ?? 0).toInt(),
      paceMinPerKm: (data["pace_min_per_km"] ?? 0.0).toDouble(),
      calories: (data["calories"] ?? 0).toDouble(),
      date: (data["date"] is Timestamp) 
          ? (data["date"] as Timestamp).toDate() 
          : DateTime.now(),
      routePoints: points,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "distance_km": distanceKm,
      "duration_seconds": durationSeconds,
      "pace_min_per_km": paceMinPerKm,
      "calories": calories,
      "date": Timestamp.fromDate(date),
      // Serializar puntos para Firestore
      "points": routePoints.map((p) => {
        "lat": p.latitude,
        "lng": p.longitude
      }).toList(),
    };
  }
}
