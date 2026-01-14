import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/training_controller.dart';

class ActiveRunScreen extends StatefulWidget {
  const ActiveRunScreen({Key? key}) : super(key: key);

  @override
  _ActiveRunScreenState createState() => _ActiveRunScreenState();
}

class _ActiveRunScreenState extends State<ActiveRunScreen> {
  GoogleMapController? _mapController;
  bool _isMapFocused = false; // Si el usuario interactuó con el mapa

  @override
  Widget build(BuildContext context) {
    // Obtener controller sin escuchar para los botones y estructura
    // Escucharemos cambios específicos con Consumer anidados o Selector
    final ctrl = context.read<TrainingController>();

    return Scaffold(
      body: Stack(
        children: [
          // 1. MAPA (Fondo)
          // Usamos Selector para reconstruir el mapa solo cuando cambie la ruta o posición
          // y no cada segundo con el timer.
          Positioned.fill(
            child: Selector<TrainingController, List<LatLng>>(
              selector: (_, c) => c.pathPoints,
              shouldRebuild: (prev, next) => true, // Rebuild para pintar la linea
              builder: (context, pathPoints, child) {
                 return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: ctrl.currentPosition ?? const LatLng(-3.99313, -79.20422),
                    zoom: 17,
                  ),
                  zoomControlsEnabled: false,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId("active_run"),
                      points: pathPoints,
                      color: const Color(0xFFE67E22),
                      width: 6,
                      jointType: JointType.round,
                      startCap: Cap.roundCap,
                      endCap: Cap.roundCap,
                    ),
                    if (ctrl.ghostRoute != null)
                      Polyline(
                        polylineId: const PolylineId("ghost_route"),
                        points: ctrl.ghostRoute!,
                        color: Colors.grey.withOpacity(0.5),
                        width: 6,
                      ),
                  },
                  onMapCreated: (c) {
                    _mapController = c;
                    // Centrar mapa si ya tenemos posición
                    if (ctrl.currentPosition != null) {
                       c.animateCamera(CameraUpdate.newLatLng(ctrl.currentPosition!));
                    }
                  },
                  onCameraMoveStarted: () {
                     if (mounted) setState(() => _isMapFocused = true);
                  },
                );
              },
            ),
          ),

          // 2. BOTÓN RE-CENTRAR
          if (_isMapFocused)
            Positioned(
              top: 50,
              right: 16,
              child: FloatingActionButton.small(
                backgroundColor: Colors.white,
                child: const Icon(Icons.center_focus_strong, color: Colors.black),
                onPressed: () {
                  setState(() => _isMapFocused = false);
                  if (ctrl.currentPosition != null && _mapController != null) {
                     _mapController!.animateCamera(CameraUpdate.newLatLng(ctrl.currentPosition!));
                  }
                },
              ),
            ),

          // 3. DATOS Y CONTROLES (Parte Inferior)
          // Aquí sí necesitamos escuchar cambios de tiempo y stats
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Consumer<TrainingController>(
              builder: (context, ctrl, child) {
                // Auto-center logic (Moved here to verify periodically)
                if (ctrl.currentPosition != null && _mapController != null && !_isMapFocused) {
                  _mapController!.animateCamera(CameraUpdate.newLatLng(ctrl.currentPosition!));
                }

                return Container(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5)
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TIEMPO GRANDE
                      Text(
                        _formatTime(ctrl.secondsElapsed),
                        style: const TextStyle(
                          fontSize: 64, 
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF333333),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const Text("TIEMPO", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 2)),
                      
                      const SizedBox(height: 30),

                      // GRID DISTANCIA | RITMO
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _DataCell(
                            label: "DISTANCIA (km)",
                            value: ctrl.distanceKm.toStringAsFixed(2),
                          ),
                          Container(width: 1, height: 40, color: Colors.grey[300]),
                          _DataCell(
                            label: "RITMO (min/km)",
                            value: _formatPace(ctrl.currentPace),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40),

                      // CONTROLES
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (ctrl.state == TrainingState.running)
                            FloatingActionButton.large(
                              backgroundColor: Colors.black,
                              child: const Icon(Icons.pause, color: Colors.white, size: 40),
                              onPressed: () => ctrl.pauseTraining(),
                            ),
                          
                          if (ctrl.state == TrainingState.paused) ...[
                            FloatingActionButton.large(
                               backgroundColor: const Color(0xFF3A7D6E),
                               child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                               onPressed: () => ctrl.resumeTraining(),
                            ),
                            const SizedBox(width: 30),
                            FloatingActionButton.large(
                               backgroundColor: Colors.redAccent,
                               child: const Icon(Icons.stop, color: Colors.white, size: 40),
                               onPressed: () async {
                                 bool? confirm = await showDialog(
                                   context: context,
                                   builder: (c) => AlertDialog(
                                     title: const Text("¿Terminar entrenamiento?"),
                                     actions: [
                                       TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancelar")),
                                       TextButton(
                                         onPressed: () => Navigator.pop(c, true), 
                                         child: const Text("Terminar", style: TextStyle(color: Colors.red))
                                       ),
                                     ],
                                   )
                                 );
                                 if (confirm == true) {
                                   ctrl.stopTraining();
                                 }
                               },
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    if (h > 0) {
      return "${h.toString()}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  String _formatPace(double pace) {
    if (pace == 0 || pace.isInfinite) return "-'--''";
    int min = pace.floor();
    int sec = ((pace - min) * 60).round();
    return "$min'${sec.toString().padLeft(2, '0')}''";
  }
}

class _DataCell extends StatelessWidget {
  final String label;
  final String value;
  const _DataCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1)
        ),
      ],
    );
  }
}
