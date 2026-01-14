import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/training_controller.dart';
import '../../../../pantallas/local_route_manager.dart'; // Correct path to lib/pantallas

class PreRunScreen extends StatefulWidget {
  final Widget? bottomNavigationBar;
  const PreRunScreen({Key? key, this.bottomNavigationBar}) : super(key: key);

  @override
  _PreRunScreenState createState() => _PreRunScreenState();
}

class _PreRunScreenState extends State<PreRunScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios del controlador (como la ubicación inicial)
    final controller = context.watch<TrainingController>();

    // Si tenemos una posición inicial, mover la cámara
    if (controller.currentPosition != null && _mapController != null) {
       // Nota: Solo movemos si el usuario no está interactuando (opcional)
       // Para Pre-Run, queremos centrarlo al inicio
    }

    return Scaffold(
      bottomNavigationBar: widget.bottomNavigationBar,
      body: Stack(
        children: [
          // 1. EL MAPA (Fondo)
          // 1. EL MAPA (Fondo)
          Positioned.fill(
            child: Consumer<TrainingController>(
              builder: (context, ctrl, child) {
                final initialPos = ctrl.currentPosition ?? const LatLng(-3.99313, -79.20422); // Loja default
                
                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: initialPos,
                    zoom: 16,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false, // Usaremos uno custom
                  zoomControlsEnabled: false,
                  onMapCreated: (mapCtrl) {
                    _mapController = mapCtrl;
                    // Si ya había posición, animar ahí
                    if (ctrl.currentPosition != null) {
                      mapCtrl.animateCamera(CameraUpdate.newLatLng(ctrl.currentPosition!));
                    }
                  },
                  // Si hay ruta fantasma cargada, dibujarla
                  polylines: ctrl.ghostRoute != null 
                    ? {
                        Polyline(
                          polylineId: const PolylineId("ghost_route"),
                          points: ctrl.ghostRoute!,
                          color: Colors.grey.withOpacity(0.6),
                          width: 5,
                        )
                      }
                    : {},
                );
              },
            ),
          ),

          // 2. GRADIENTE SUPERIOR (Para visibilidad de iconos si hubiera)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // 3. BOTÓN ATRÁS (Para cancelar la preparación)
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  context.read<TrainingController>().cancelPreparation();
                },
              ),
            ),
          ),

          // 3. PANEL INFERIOR (Glassmorphism / Control)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                   BoxShadow(
                     color: Colors.black12,
                     blurRadius: 20,
                     offset: Offset(0, -5),
                   )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Selector de Actividad (Simple por ahora)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActivityIcon(icon: Icons.directions_run, label: "Correr", isSelected: true),
                      const SizedBox(width: 20),
                      _ActivityIcon(icon: Icons.directions_walk, label: "Caminar", isSelected: false),
                      const SizedBox(width: 20),
                      _ActivityIcon(icon: Icons.directions_bike, label: "Ciclismo", isSelected: false),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // BOTÓN DE INICIO GIGANTE
                  GestureDetector(
                    onTap: () {
                      context.read<TrainingController>().startTraining();
                    },
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE67E22), // Naranja acción
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE67E22).withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "INICIAR",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botón Rutas y Config
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          // TODO: Abrir selector de rutas (LocalRouteManager)
                          _showRoutesModal(context);
                        },
                        icon: const Icon(Icons.map, color: Color(0xFF3A7D6E)),
                        label: const Text("Cargar Ruta", style: TextStyle(color: Color(0xFF3A7D6E))),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.grey),
                        onPressed: () {
                          // TODO: Settings
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          
          // 4. Botón flotante para ubicarme
          Positioned(
            right: 16,
            bottom: 320, // Ajustar según altura panel
            child: FloatingActionButton(
               mini: true,
               backgroundColor: Colors.white,
               child: const Icon(Icons.my_location, color: Colors.black87),
               onPressed: () async {
                 final ctrl = context.read<TrainingController>();
                 if (ctrl.currentPosition != null && _mapController != null) {
                   _mapController!.animateCamera(CameraUpdate.newLatLng(ctrl.currentPosition!));
                 }
               },
            ),
          )
        ],
      ),
    );
  }

  void _showRoutesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // En un futuro, esto podría ser un widget reutilizable
        // Por ahora, usamos el RutasTabContent existente o algo similar
        // O cargamos las rutas usando LocalRouteManager directamente
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Seleccionar Ruta", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: LocalRouteManager.loadLocalRoutes(),
                builder: (ctx, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final routes = snapshot.data!;
                  if (routes.isEmpty) return const Text("No hay rutas guardadas.");
                  
                  return Expanded(
                    child: ListView.builder(
                      itemCount: routes.length,
                      itemBuilder: (ctx, i) {
                        final r = routes[i];
                        final double dist = r['distance'] ?? 0.0;
                         return ListTile(
                           leading: const Icon(Icons.route),
                           title: Text("Ruta ${r['date']}"),
                           subtitle: Text("${dist.toStringAsFixed(2)} km"),
                           onTap: () {
                             // Cargar ruta en el controlador
                             final List<dynamic> pointsJson = r['points'];
                             final List<LatLng> points = pointsJson.map((p) => LatLng(p['lat'], p['lng'])).toList();
                             context.read<TrainingController>().loadRouteToFollow(points);
                             Navigator.pop(context);
                           },
                         );
                      },
                    ),
                  );
                },
              )
            ],
          ),
        );
      },
    );
  }
}

class _ActivityIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  
  const _ActivityIcon({
    Key? key,
    required this.icon,
    required this.label,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3A7D6E).withOpacity(0.1) : Colors.transparent,
            shape: BoxShape.circle,
            border: isSelected ? Border.all(color: const Color(0xFF3A7D6E), width: 2) : Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Icon(
            icon,
            color: isSelected ? const Color(0xFF3A7D6E) : Colors.grey,
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF3A7D6E) : Colors.grey,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
