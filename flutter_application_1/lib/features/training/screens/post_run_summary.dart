import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/training_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import '../services/run_service.dart'; // Si lo necesitamos aquí o en el controller

class PostRunSummary extends StatelessWidget {
  const PostRunSummary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<TrainingController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Resumen", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      // 1. CAMBIO: Usamos SingleChildScrollView para que el teclado no rompa el diseño
      body: SingleChildScrollView(
        child: Column(
          children: [
            // MAPA ESTÁTICO
            SizedBox(
              height: 300,
              width: double.infinity,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: ctrl.pathPoints.isNotEmpty
                      ? ctrl.pathPoints.last
                      : const LatLng(0, 0),
                  zoom: 15,
                ),
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                onMapCreated: (mapCtrl) {
                  if (ctrl.pathPoints.isNotEmpty) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      mapCtrl.animateCamera(
                        CameraUpdate.newLatLngBounds(
                          _boundsFromLatLngList(ctrl.pathPoints),
                          50,
                        ),
                      );
                    });
                  }
                },
                polylines: {
                  Polyline(
                    polylineId: const PolylineId("finished_route"),
                    points: ctrl.pathPoints,
                    color: const Color(0xFFE67E22),
                    width: 5,
                  ),
                },
              ),
            ),

            // 2. CONTENIDO (Eliminamos Expanded)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Añadimos valores por defecto para evitar el error de 'Null'
                      _StatItem(
                        "Distancia",
                        "${(ctrl.distanceKm ?? 0.0).toStringAsFixed(2)} km",
                      ),
                      _StatItem(
                        "Tiempo",
                        _formatTime(ctrl.secondsElapsed ?? 0),
                      ),
                      _StatItem("Ritmo", _formatPace(ctrl.currentPace ?? 0.0)),
                    ],
                  ),
                  const Divider(height: 40),

                  TextField(
                    decoration: InputDecoration(
                      hintText: "Título de la actividad",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),

                  const SizedBox(
                    height: 40,
                  ), // Sustituimos Spacer() por espacio fijo

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => ctrl.reset(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Descartar",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid != null) {
                              await ctrl.saveRun(uid);
                              ctrl.reset();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE67E22),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Guardar",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Espacio extra al final para que el teclado no tape el botón al escribir
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper para bounds
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0!) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  String _formatTime(int seconds) {
    // Reutilizar lógica o mover a utils
    int m = (seconds / 60).floor();
    int s = seconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  String _formatPace(double pace) {
    if (pace.isInfinite || pace.isNaN) return "0:00";
    int m = pace.floor();
    int s = ((pace - m) * 60).round();
    return "$m'${s.toString().padLeft(2, '0')}''";
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
