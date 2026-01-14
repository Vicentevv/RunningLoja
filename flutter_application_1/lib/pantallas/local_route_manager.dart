import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Definimos los colores aquí para que este archivo sea independiente
// (O podrías importarlos de tu archivo de constantes si tienes uno)
const Color kPrimaryGreen = Color(0xFF3A7D6E);
const Color kSecondaryTextColor = Color(0xFF666666);

class LocalRouteManager {
  // --- 0. Solicitar Permisos de Almacenamiento ---
  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    if (Platform.isAndroid) {
      // Para Android 12+, también solicitar MANAGE_EXTERNAL_STORAGE si es necesario
      if (!status.isGranted) {
        final manageStatus = await Permission.manageExternalStorage.request();
        return manageStatus.isGranted;
      }
    }
    return status.isGranted;
  }

  // --- 1. Lógica Matemática: Calcular Zoom del Mapa ---
  static LatLngBounds getBoundsFromPoints(List<LatLng> list) {
    if (list.isEmpty) throw Exception("Lista de puntos vacía");
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  // --- 2. Lógica de Guardado: Escribir en Disco ---
  static Future<void> saveRoute({
    required List<LatLng> points,
    required Uint8List imageBytes,
    required double distanceKm,
    required int durationSeconds,
  }) async {
    try {
      // Solicitar permisos antes de guardar
      bool hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        debugPrint("Permiso de almacenamiento denegado");
        throw Exception("No hay permisos para guardar archivos");
      }

      final directory = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // A. Guardar Imagen PNG
      final File imageFile = File('${directory.path}/route_$timestamp.png');
      await imageFile.writeAsBytes(imageBytes);

      // B. Guardar Datos JSON
      List<Map<String, double>> pointsJson = points
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList();

      final routeData = {
        'id': timestamp,
        'date': DateTime.now().toIso8601String(),
        'distance': distanceKm,
        'time': durationSeconds,
        'imagePath': imageFile.path,
        'points': pointsJson,
      };

      final File jsonFile = File('${directory.path}/route_$timestamp.json');
      await jsonFile.writeAsString(json.encode(routeData));

      debugPrint("Ruta guardada exitosamente: ${jsonFile.path}");
    } catch (e) {
      debugPrint("Error guardando ruta local: $e");
      rethrow;
    }
  }

  // --- 3. Lógica de Lectura: Leer del Disco ---
  static Future<List<Map<String, dynamic>>> loadLocalRoutes() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      // Filtrar archivos .json que sean de rutas
      final List<FileSystemEntity> files = directory.listSync().where((file) {
        return file.path.endsWith('.json') && file.path.contains('route_');
      }).toList();

      // Ordenar por más reciente primero
      files.sort((a, b) => b.path.compareTo(a.path));

      List<Map<String, dynamic>> loadedRoutes = [];

      for (var file in files) {
        final String content = await File(file.path).readAsString();
        final data = json.decode(content) as Map<String, dynamic>;
        loadedRoutes.add(data);
      }
      return loadedRoutes;
    } catch (e) {
      debugPrint("Error cargando rutas: $e");
      return [];
    }
  }
}

// --- 4. Widget UI: La pestaña de Rutas ---
class RutasTabContent extends StatefulWidget {
  const RutasTabContent({Key? key}) : super(key: key);

  @override
  _RutasTabContentState createState() => _RutasTabContentState();
}

class _RutasTabContentState extends State<RutasTabContent> {
  late Future<List<Map<String, dynamic>>> _routesFuture;

  @override
  void initState() {
    super.initState();
    _routesFuture = LocalRouteManager.loadLocalRoutes();
  }

  // Método para recargar la lista (útil si acabas de guardar una ruta)
  void refresh() {
    setState(() {
      _routesFuture = LocalRouteManager.loadLocalRoutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _routesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'No hay rutas guardadas.\n¡Sal a entrenar para generar tu primera ruta estilo Strava!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kSecondaryTextColor),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: refresh,
                  icon: const Icon(Icons.refresh, color: kPrimaryGreen),
                  label: const Text(
                    "Recargar",
                    style: TextStyle(color: kPrimaryGreen),
                  ),
                ),
              ],
            ),
          );
        }

        final routes = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async => refresh(),
          child: ListView.builder(
            // --- INICIO DE LA CORRECCIÓN ---
            shrinkWrap:
                true, // Hace que la lista ocupe solo el espacio necesario
            physics:
                const NeverScrollableScrollPhysics(), // Evita que la lista tenga su propio scroll (conflicto con el scroll principal)
            // --- FIN DE LA CORRECCIÓN ---
            padding: const EdgeInsets.all(16),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              final File imgFile = File(route['imagePath']);
              final double dist = route['distance'] ?? 0.0;
              final DateTime date =
                  DateTime.tryParse(route['date']) ?? DateTime.now();

              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                elevation: 6,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // IMAGEN GENERADA
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            imgFile,
                            fit: BoxFit.cover,
                            errorBuilder: (c, o, s) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          // Gradiente para texto
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.6),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 16,
                            child: Text(
                              "${date.day}/${date.month}/${date.year}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // DATOS
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoColumn(
                            "Distancia",
                            "${dist.toStringAsFixed(2)} km",
                          ),
                          _buildInfoColumn(
                            "Tiempo",
                            _formatSeconds(route['time'] ?? 0),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.share_outlined,
                              color: kPrimaryGreen,
                            ),
                            onPressed: () {
                              // Aquí podrías agregar share_plus para compartir la imagen
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: kSecondaryTextColor),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  String _formatSeconds(int seconds) {
    int m = (seconds / 60).floor();
    int s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }
}
