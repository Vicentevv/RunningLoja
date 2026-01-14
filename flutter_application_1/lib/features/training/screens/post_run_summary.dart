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
      body: Column(
        children: [
          // 1. MAPA ESTÁTICO DE LA RUTA
          SizedBox(
            height: 300,
            width: double.infinity,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: ctrl.pathPoints.isNotEmpty ? ctrl.pathPoints.last : const LatLng(0,0),
                zoom: 15,
              ),
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              // CALCULAMOS BOUNDS PARA MOSTRAR TODA LA RUTA
              onMapCreated: (mapCtrl) {
                 if (ctrl.pathPoints.isNotEmpty) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      mapCtrl.animateCamera(CameraUpdate.newLatLngBounds(
                        _boundsFromLatLngList(ctrl.pathPoints),
                        50 // padding
                      ));
                    });
                 }
              },
              polylines: {
                Polyline(
                  polylineId: const PolylineId("finished_route"),
                  points: ctrl.pathPoints,
                  color: const Color(0xFFE67E22),
                  width: 5,
                )
              },
            ),
          ),

          // 2. ESTADÍSTICAS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatItem("Distancia", "${ctrl.distanceKm.toStringAsFixed(2)} km"),
                      _StatItem("Tiempo", _formatTime(ctrl.secondsElapsed)),
                      _StatItem("Ritmo", _formatPace(ctrl.currentPace)),
                    ],
                  ),
                  const Divider(height: 40),
                  
                  // INPUT NOMBRE / NOTAS (Opcional)
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Título de la actividad (ej. Carrera matutina)",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),

                  const Spacer(),

                  // BOTONES ACCIÓN
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                             // Descartar
                             // Debería mostrar diálogo confirmación
                             ctrl.reset(); // Método que resetea a IDLE
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Descartar", style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                         child: ElevatedButton(
                           onPressed: () async {
                             final uid = FirebaseAuth.instance.currentUser?.uid;
                             if (uid != null) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('Guardando actividad...')),
                               );
                               await ctrl.saveRun(uid);
                               ctrl.reset();
                             } else {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('Error: No usuario logueado')),
                               );
                             }
                           },
                           style: ElevatedButton.styleFrom(
                             backgroundColor: const Color(0xFFE67E22),
                             padding: const EdgeInsets.symmetric(vertical: 16),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                           ),
                           child: const Text("Guardar Actividad", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                         ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
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
    return LatLngBounds(northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
  }

  String _formatTime(int seconds) {
    // Reutilizar lógica o mover a utils
    int m = (seconds / 60).floor();
    int s = seconds % 60;
    return "$m:${s.toString().padLeft(2,'0')}";
  }

  String _formatPace(double pace) {
    if(pace.isInfinite || pace.isNaN) return "0:00";
    int m = pace.floor();
    int s = ((pace - m)*60).round();
    return "$m'${s.toString().padLeft(2,'0')}''";
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
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
