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

  // --- 1. De Firestore a Objeto Dart ---
  factory RunModel.fromDocument(DocumentSnapshot doc) {
    Map data = doc.data() as Map;

    List<LatLng> points = [];
    if (data['points'] != null) {
      try {
        points = (data['points'] as List).map((p) {
          return LatLng(
            (p['lat'] as num).toDouble(),
            (p['lng'] as num).toDouble(),
          );
        }).toList();
      } catch (e) {
        print("Error parsing route points: $e");
      }
    }

    return RunModel(
      id: doc.id,
      // Mantenemos el soporte para nombres de campos antiguos y nuevos
      distanceKm: (data["distance_km"] ?? data["distance"] ?? 0).toDouble(),
      durationSeconds: (data["duration_seconds"] ?? data["duration"] ?? 0)
          .toInt(),
      paceMinPerKm: (data["pace_min_per_km"] ?? 0.0).toDouble(),
      calories: (data["calories"] ?? 0).toDouble(),
      date: (data["date"] is Timestamp)
          ? (data["date"] as Timestamp).toDate()
          : DateTime.now(),
      routePoints: points,
    );
  }

  // --- 2. De Objeto Dart a JSON (Para guardar en Firestore) ---
  Map<String, dynamic> toJson() {
    return {
      "distance_km": double.parse(
        distanceKm.toStringAsFixed(3),
      ), // Guardar con 3 decimales
      "duration_seconds": durationSeconds,
      "pace_min_per_km": double.parse(paceMinPerKm.toStringAsFixed(2)),
      "calories": calories.roundToDouble(),
      "date": Timestamp.fromDate(date),
      // OPTIMIZACIÓN: Limitamos la precisión de las coordenadas a 6 decimales
      "points": routePoints
          .map(
            (p) => {
              "lat": double.parse(p.latitude.toStringAsFixed(6)),
              "lng": double.parse(p.longitude.toStringAsFixed(6)),
            },
          )
          .toList(),
    };
  }
}
