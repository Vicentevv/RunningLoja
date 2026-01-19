import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'dart:math' show sqrt, cos, sin, atan2, pi, Random;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'local_route_manager.dart'; // <--- Importa el archivo que acabamos de crear
import 'dart:typed_data'; // Necesario para Uint8List
import 'package:provider/provider.dart';
import '../features/training/controllers/training_controller.dart';
import '../features/training/screens/run_detail_screen.dart'; // Importar detalle
import '../modelos/RunModel.dart'; // Importar modelo

// --- Definición de Colores ---
const Color kPrimaryGreen = Color(0xFF3A7D6E);
const Color kLightGreenBackground = Color(0xFFF0F5F3);
const Color kCardBackgroundColor = Colors.white;
const Color kPrimaryTextColor = Color(0xFF333333);
const Color kSecondaryTextColor = Color(0xFF666666);
const Color kAccentOrange = Color(0xFFE67E22);

class LegacyTrainingScreen extends StatefulWidget {
  const LegacyTrainingScreen({Key? key}) : super(key: key);

  @override
  _LegacyTrainingScreenState createState() => _LegacyTrainingScreenState();
}

class _LegacyTrainingScreenState extends State<LegacyTrainingScreen> {
  int _selectedNavBarIndex = 4; // 4 es 'Entrenar'
  int _selectedTabIndex = 0; // 0 es 'Inicio'
  bool _isTraining = false; // Estado para saber si se está entrenando

  // --- Para el Calendario ---
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  // Días con sesión (para marcar en calendario)
  Set<DateTime> _streakDays = {};

  // --- Para el Mapa y Ubicación ---
  GoogleMapController? _mapController;
  Location _location = Location();
  LatLng _currentPosition = const LatLng(
    3.9936,
    -79.2045,
  ); // Posición inicial (Loja)
  bool _isLoadingLocation = true;
  bool _simulateMode = false; // Si true, usar simulación en lugar de GPS
  // StreamSubscription para rastrear cambios de ubicación (para cancelar después)
  dynamic _locationSubscription;

  // --- Estadísticas de Entrenamiento en Tiempo Real ---
  int _elapsedSeconds = 0; // Tiempo transcurrido en segundos
  double _totalDistance = 0.0; // Distancia total en km
  double _pace = 0.0; // Ritmo en min/km
  LatLng? _lastPosition; // Última posición registrada para calcular distancia
  Timer? _trainingTimer; // Timer para actualizar estadísticas cada segundo
  final List<LatLng> _routePoints =
      []; // Puntos del recorrido para dibujar la ruta
  // --- Datos históricos y calculados desde Firestore ---
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sessionsSub;
  List<Map<String, dynamic>> _sessions = [];
  double _weeklyDistance = 0.0;
  int _weeklyTimeSeconds = 0;
  double _weeklyPace = 0.0;
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _requestLocationPermission();
    _listenToSessions();
  }

  void _listenToSessions() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _sessionsSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .orderBy('date', descending: true)
        .snapshots()
        .listen(
          (qs) {
            if (!mounted) return;

            final now = DateTime.now();
            // Semana actual: consideramos lunes como inicio
            final weekStart = DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(Duration(days: now.weekday - 1));

            List<Map<String, dynamic>> sessions = [];
            double weeklyDistance = 0.0;
            int weeklyTime = 0;
            Set<String> sessionDateKeys = {};
            
            for (final doc in qs.docs) {
              // USAR MODELO CENTRALIZADO
              RunModel run;
              try {
                run = RunModel.fromDocument(doc);
              } catch (e) {
                print("Error parseando carrera ${doc.id}: $e");
                continue;
              }

              // Convertir a mapa simple para la UI legacy (hasta que se migre toda la UI)
              final session = run.toJson();
              session['id'] = run.id; // Asegurar ID
              // La fecha ya viene como DateTime en el modelo, toJson lo pasa a Timestamp, 
              // pero la UI espera DateTime o Timestamp, así que mejor usamos el objeto run directamente si pudiéramos,
              // pero para minimizar cambios, reconstruimos el mapa con lo que espera la UI
              
              sessions.add({
                'id': run.id,
                'date': run.date,
                'distance': run.distanceKm,
                'duration': run.durationSeconds,
                'pace': run.paceMinPerKm,
                'calories': run.calories,
                'routePoints': run.routePoints, // <--- AÑADIDO: Puntos para el detalle
              });
 
              // acumular semana actual
              if (!run.date.isBefore(weekStart)) {
                weeklyDistance += run.distanceKm;
                weeklyTime += run.durationSeconds;
              }

              // registrar día (yyyy-mm-dd)
              final key =
                  '${run.date.year.toString().padLeft(4, '0')}-${run.date.month.toString().padLeft(2, '0')}-${run.date.day.toString().padLeft(2, '0')}';
              sessionDateKeys.add(key);
            }

            // calcular racha actual (días consecutivos con sesión, desde hoy hacia atrás)
            int streak = 0;
            DateTime cursor = DateTime(now.year, now.month, now.day);
            while (true) {
              final key =
                  '${cursor.year.toString().padLeft(4, '0')}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}';
              if (sessionDateKeys.contains(key)) {
                streak++;
                cursor = cursor.subtract(const Duration(days: 1));
              } else {
                break;
              }
            }

            // generar set de DateTime para marcar calendario
            Set<DateTime> streakDays = {};
            for (final k in sessionDateKeys) {
              final parts = k.split('-');
              final d = DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              );
              streakDays.add(d);
            }

            double weeklyPace = 0.0;
            if (weeklyDistance > 0) {
              weeklyPace = (weeklyTime / 60.0) / weeklyDistance;
            }

            setState(() {
              _sessions = sessions;
              _weeklyDistance = weeklyDistance;
              _weeklyTimeSeconds = weeklyTime;
              _weeklyPace = weeklyPace;
              _currentStreak = streak;
              _streakDays = streakDays;
            });
          },
          onError: (e) {
            print('Error listening sessions: $e');
          },
        );
  }

  // Solicita permiso y obtiene la ubicación actual
  void _requestLocationPermission() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
    });
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        if (!mounted) return;
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }
    }

    final locationData = await _location.getLocation();
    if (!mounted) return;
    setState(() {
      _currentPosition = LatLng(
        locationData.latitude!,
        locationData.longitude!,
      );
      _isLoadingLocation = false;
      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentPosition));
    });
  }

  void _onNavBarTap(int index) {
    setState(() {
      _selectedNavBarIndex = index;
    });
    if (index == 0) {
      Navigator.pushNamed(context, '/HomeScreen');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/EventosScreen');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/ProfileScreen');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/CommunityScreen');
    } else if (index == 4) {
      Navigator.pushNamed(context, '/TrainingScreen');
    }
  }

  void _onTopTabTap(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  // --- Funciones para Iniciar/Parar ---
  // --- Funciones para Iniciar/Parar ---
  Future<void> _startTraining() async {
    // NUEVA LÓGICA: Iniciar MODO PREPARACIÓN (PreRunScreen)
    context.read<TrainingController>().prepareTraining();
  }

  Future<void> _stopTraining() async {
    if (!mounted) return;

    print("--- INICIANDO PROCESO DE DETENER ---");
    print(
      "📊 Datos: distancia=${_totalDistance.toStringAsFixed(2)}km, tiempo=${_elapsedSeconds}s, puntos=${_routePoints.length}",
    );

    // 1. Mostrar diálogo de "Guardando..."
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: kPrimaryGreen),
            SizedBox(height: 16),
            Text(
              "Guardando ruta...",
              style: TextStyle(
                color: Colors.white,
                decoration: TextDecoration.none,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );

    Uint8List? imageBytes;

    try {
      // --- FASE 1: CAPTURA DE IMAGEN (Mientras seguimos en Full Screen) ---
      // Solo intentamos la foto si tenemos puntos y el mapa está activo
      if (_mapController != null && _routePoints.isNotEmpty) {
        print("Intentando ajustar cámara...");

        // A. Ajustar cámara (con try-catch por si los puntos son inválidos)
        try {
          // Si solo hay 1 punto, no podemos calcular bounds, hacemos zoom al punto
          if (_routePoints.length > 1) {
            final bounds = LocalRouteManager.getBoundsFromPoints(_routePoints);
            await _mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 50),
            );
          } else {
            await _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(_routePoints.first, 17),
            );
          }
        } catch (e) {
          print("Error ajustando cámara (no crítico): $e");
        }

        // B. PAUSA CRÍTICA: Dar tiempo al mapa para renderizar los tiles nuevos
        // Si no esperamos, el snapshot sale gris o crashea la app
        await Future.delayed(const Duration(milliseconds: 1000));

        // C. Tomar la foto
        print("Tomando snapshot...");
        try {
          imageBytes = await _mapController!.takeSnapshot();
          print("Snapshot tomado: ${imageBytes != null ? 'OK' : 'NULL'}");
        } catch (e) {
          print(
            "Error al tomar snapshot (La app no crasheará, solo no habrá foto): $e",
          );
          imageBytes = null;
        }
      }

      // --- FASE 2: GUARDADO LOCAL ---
      print(
        "📁 Intentando guardar ruta local... (imageBytes=${imageBytes != null})",
      );
      if (imageBytes != null) {
        try {
          await LocalRouteManager.saveRoute(
            points: _routePoints,
            imageBytes: imageBytes,
            distanceKm: _totalDistance,
            durationSeconds: _elapsedSeconds,
          );
          print("✅ Ruta local guardada exitosamente");
        } catch (e) {
          print("❌ Error en guardado local: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error al guardar la ruta: $e")),
            );
          }
        }
      } else {
        print("⚠️ No hay imagen para guardar (snapshot fue NULL)");
      }
    } catch (e) {
      print("Error general durante el proceso de guardado: $e");
      // Cerrar el diálogo de error
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
      setState(() {
        _isTraining = false;
      });
      return;
    }

    // --- FASE 3: RESTAURAR ESTADO DEL TELEFONO ---
    // Recién AHORA, que ya terminamos con el mapa, restauramos la UI.
    // Esto evita el conflicto de redimensionamiento que causaba el crash.

    print("🔄 FASE 3: Restaurando estado...");
    if (mounted) {
      print("✓ Widget aún montado, continuando...");
      // Restaurar Pantalla Normal
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      // Restaurar GPS
      try {
        _location.changeSettings(
          accuracy: LocationAccuracy.balanced,
          interval: 10000,
        );
      } catch (_) {}

      // Guardar estadísticas globales (Firebase)
      if (_elapsedSeconds > 0 && _totalDistance > 0) {
        print("🔥 Guardando sesión en Firebase...");
        try {
          // Esperar a que Firebase termine, con timeout de 15 segundos
          await _saveSession().timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print(
                "⚠️ Timeout guardando en Firebase (pero se continuará guardando en background)",
              );
            },
          );
          print("✅ Sesión guardada en Firebase");
        } catch (e) {
          print("❌ Error Firebase: $e");
        }
      } else {
        print("⏭️ Saltando Firebase (datos insuficientes)");
      }

      // Cerrar diálogo de carga
      print("🚪 Intentando cerrar diálogo...");
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
        print("✅ Diálogo cerrado");
      } else {
        print("⚠️ No hay diálogo para cerrar");
      }

      // Finalizar estado de entrenamiento
      setState(() {
        _isTraining = false;
      });

      _locationSubscription?.cancel();
      _trainingTimer?.cancel();

      // Mostrar éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Ruta guardada: ${_totalDistance.toStringAsFixed(2)} km en ${(_elapsedSeconds ~/ 60)} min',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print("🎉 PROCESO COMPLETADO");
    } else {
      print("❌ Widget no está montado");
    }
  }

  Future<void> _saveSession() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final uid = user.uid;

      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);
      final snapshot = await userDocRef.get();

      double existingDistance = 0.0;
      int existingTime = 0;
      int existingSessions = 0;

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        // Leer posibles nombres de campo compatibles
        existingDistance =
            (data['totalDistance'] ?? data['total_distance'] ?? 0).toDouble();
        existingTime =
            (data['total_time_seconds'] ?? data['totalTimeSeconds'] ?? 0)
                .toInt();
        existingSessions =
            (data['totalRuns'] ??
                    data['session_count'] ??
                    data['sessionCount'] ??
                    0)
                .toInt();
      }

      final newTotalDistance = existingDistance + _totalDistance;
      final newTotalTime = existingTime + _elapsedSeconds;
      final newSessionCount = existingSessions + 1;

      // Calculamos nuevo ritmo promedio en min/km
      double newAvgPaceMinPerKm = 0.0;
      if (newTotalDistance > 0) {
        newAvgPaceMinPerKm = (newTotalTime / 60.0) / newTotalDistance;
      }

      final sessionData = {
        'date': Timestamp.now(),
        'duration_seconds': _elapsedSeconds,
        'distance_km': double.parse(_totalDistance.toStringAsFixed(3)),
        'pace_min_per_km': double.parse(_pace.toStringAsFixed(3)),
      };

      await userDocRef.collection('sessions').add(sessionData);

      // Actualizamos tanto campos camelCase como snake_case para compatibilidad
      await userDocRef.set({
        'totalDistance': double.parse(newTotalDistance.toStringAsFixed(3)),
        'total_distance': double.parse(newTotalDistance.toStringAsFixed(3)),
        'total_time_seconds': newTotalTime,
        'totalTimeSeconds': newTotalTime,
        'totalRuns': newSessionCount,
        'session_count': newSessionCount,
        'sessionCount': newSessionCount,
        'averagePace': _formatPace(newAvgPaceMinPerKm),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error guardando sesión: $e');
    }
  }

  // Calcula distancia entre dos puntos (Haversine formula) en km
  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadiusKm = 6371;
    double dLat = _degreesToRadians(end.latitude - start.latitude);
    double dLon = _degreesToRadians(end.longitude - start.longitude);
    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(start.latitude)) *
            cos(_degreesToRadians(end.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Formatea tiempo transcurrido a MM:SS
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Formatea ritmo a MM:SS /km
  String _formatPace(double pace) {
    if (pace == 0) return '0:00';
    int minutes = pace.toInt();
    int seconds = ((pace - minutes) * 60).toInt();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Formatea duración a H:MM:SS o MM:SS si es menor a 1 hora
  String _formatDurationHMS(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    if (h > 0) {
      return '${h.toString()}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // Asegúrate de cancelar el listener cuando el widget se destruya
    _locationSubscription?.cancel();
    _trainingTimer?.cancel();
    _mapController?.dispose();
    _sessionsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SI estamos entrenando, retornamos la NUEVA pantalla completa
    if (_isTraining) {
      return Scaffold(
        body:
            _buildTrainingFullScreen(), // <--- Método nuevo que crearemos abajo
      );
    }

    // SI NO estamos entrenando, retornamos tu diseño original
    return Scaffold(
      backgroundColor: kLightGreenBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [_buildHeader(), _buildTopTabBar(), _buildTabContent()],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// Header verde con estadísticas
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      decoration: const BoxDecoration(
        color: kPrimaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Fila de Título y Cámara
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Entrenar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Fila de Tarjetas de Estadísticas
          Row(
            children: [
              _buildStatCard(
                Icons.directions_run,
                'Esta semana',
                _weeklyDistance.toStringAsFixed(1),
                'kilómetros',
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                Icons.local_fire_department,
                'Racha actual',
                _currentStreak.toString(),
                'días 🔥',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tarjeta individual para las estadísticas en el header
  Widget _buildStatCard(
    IconData icon,
    String title,
    String value,
    String? unit,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unit != null) const SizedBox(width: 4),
                if (unit != null)
                  Expanded(
                    child: Text(
                      unit,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Barra de Toggles (Inicio, Histórico, Calendario, Rutas)
  Widget _buildTopTabBar() {
    final List<String> labels = ['Inicio', 'Histórico', 'Calendario', 'Rutas'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(labels.length, (index) {
          final bool isSelected = _selectedTabIndex == index;
          return ChoiceChip(
            label: Text(labels[index]),
            selected: isSelected,
            onSelected: (bool selected) {
              if (selected) {
                _onTopTabTap(index);
              }
            },
            backgroundColor: kLightGreenBackground,
            selectedColor: kPrimaryGreen,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : kPrimaryTextColor,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? kPrimaryGreen : Colors.grey.shade300,
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Contenido dinámico según el Tab seleccionado
  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: // Inicio
        return _buildInicioTab();
      case 1: // Histórico
        return _buildHistoricoTab();
      case 2: // Calendario
        return _buildCalendarioTab();
      case 3: // Rutas
        return _buildRutasTab();
      default:
        return _buildInicioTab();
    }
  }

  // --- CONTENIDO DE CADA TAB ---

  Widget _buildInicioTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLiveTrainingCard(),
          const SizedBox(height: 24),
          _buildWeekSummaryCard(),
          const SizedBox(height: 24),
          _buildSuggestedWorkoutsCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHistoricoTab() {
    if (_sessions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No hay entrenamientos registrados aún.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _sessions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final s = _sessions[index];
        final DateTime date = s['date'];
        final dist = (s['distance_km'] ?? s['distance'] ?? 0).toDouble();
        final dur = (s['duration_seconds'] ?? s['duration'] ?? 0);
        final pace = (s['pace_min_per_km'] ?? s['pace'] ?? 0);

        return ListTile(
          onTap: () {
            final run = RunModel(
              id: s['id'] ?? '',
              distanceKm: dist,
              durationSeconds: dur is int ? dur : (dur as num).toInt(),
              paceMinPerKm: (pace is num) ? (pace as num).toDouble() : 0.0,
              calories: (s['calories'] ?? 0).toDouble(),
              date: date,
              routePoints: (s['routePoints'] as List<LatLng>?) ?? [],
            );
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RunDetailScreen(run: run),
              ),
            );
          },
          leading: CircleAvatar(
            backgroundColor: kPrimaryGreen.withOpacity(0.1),
            child: Icon(Icons.directions_run, color: kPrimaryGreen),
          ),
          title: Text(
            '${dist.toStringAsFixed(2)} km • ${_formatDurationHMS(dur is int ? dur : (dur as num).toInt())}',
          ),
          subtitle: Text(
            '${date.day}/${date.month}/${date.year} • Ritmo ${_formatPace((pace is num) ? (pace as num).toDouble() : 0.0)}',
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        );
      },
    );
  }

  Widget _buildCalendarioTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay; // actualiza el foco
            });
          },
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          // --- Marcador de Racha ---
          eventLoader: (day) {
            // Normaliza el día para la comparación
            final normalizedDay = DateTime.utc(day.year, day.month, day.day);
            if (_streakDays.contains(normalizedDay)) {
              return [
                'racha',
              ]; // Retorna una lista no vacía si es un día de racha
            }
            return [];
          },
          calendarStyle: CalendarStyle(
            // Estilo para los marcadores de eventos (racha)
            markerDecoration: const BoxDecoration(
              color: kAccentOrange,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: kPrimaryGreen.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: kPrimaryGreen,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              // Normaliza el día para la comparación (sin UTC, igual que en _streakDays)
              final normalizedDay = DateTime(day.year, day.month, day.day);
              final hasTraining = _streakDays.contains(normalizedDay);

              return Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      day.day.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  if (hasTraining)
                    Positioned(
                      top: 2,
                      child: Text(
                        '🔥',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              );
            },
            todayBuilder: (context, day, focusedDay) {
              final normalizedDay = DateTime(day.year, day.month, day.day);
              final hasTraining = _streakDays.contains(normalizedDay);

              return Container(
                decoration: BoxDecoration(
                  color: kPrimaryGreen.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        day.day.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                    if (hasTraining)
                      Positioned(
                        top: 2,
                        child: Text(
                          '🔥',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              );
            },
            selectedBuilder: (context, day, focusedDay) {
              final normalizedDay = DateTime(day.year, day.month, day.day);
              final hasTraining = _streakDays.contains(normalizedDay);

              return Container(
                decoration: const BoxDecoration(
                  color: kPrimaryGreen,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        day.day.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (hasTraining)
                      Positioned(
                        top: 2,
                        child: Text(
                          '🔥',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              color: kPrimaryTextColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRutasTab() {
    return const RutasTabContent();
  }

  // --- TARJETAS DEL TAB "INICIO" ---

  /// Card de "Entrenamiento en vivo" (dinámico)
  Widget _buildLiveTrainingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        width: double.infinity,
        child: _isTraining
            ? _buildTrainingActiveView() // Vista cuando se está entrenando
            : _buildTrainingIdleView(), // Vista antes de entrenar
      ),
    );
  }

  /// Vista de "Entrenamiento en vivo" (IDLE / INACTIVO)
  Widget _buildTrainingIdleView() {
    return Column(
      children: [
        const Text(
          'Entrenamiento en vivo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kPrimaryTextColor,
          ),
        ),
        const SizedBox(height: 24),
        Icon(
          Icons.play_circle_outline,
          color: kPrimaryGreen.withOpacity(0.5),
          size: 80,
        ),
        const SizedBox(height: 16),
        const Text(
          '¿Listo para entrenar?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kSecondaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Inicia tu entrenamiento y registra tu progreso',
          style: TextStyle(color: kSecondaryTextColor, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.timer_outlined, color: Colors.white),
          label: const Text('Iniciar entrenamiento'),
          onPressed: _startTraining,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Vista de "Entrenamiento en vivo" (ACTIVO)
  Widget _buildTrainingActiveView() {
    return Column(
      children: [
        const Text(
          'Entrenamiento en vivo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kPrimaryTextColor,
          ),
        ),
        const SizedBox(height: 16),
        // --- MAPA ---
        Container(
          height: 250,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _isLoadingLocation
                ? const Center(child: CircularProgressIndicator())
                : _buildGoogleMapSafe(),
          ),
        ),
        const SizedBox(height: 24),
        // --- Estadísticas en vivo ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLiveStat("RITMO", _formatPace(_pace), "/km"),
            _buildLiveStat("TIEMPO", _formatTime(_elapsedSeconds), ""),
            _buildLiveStat(
              "DISTANCIA",
              _totalDistance.toStringAsFixed(2),
              "km",
            ),
          ],
        ),
        const SizedBox(height: 24),
        // --- Botón de Parar ---
        ElevatedButton.icon(
          icon: const Icon(Icons.stop, color: Colors.white),
          label: const Text('Parar entrenamiento'),
          onPressed: _stopTraining,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent, // Botón de parar en rojo
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Widget seguro para GoogleMap con manejo de errores
  Widget _buildGoogleMapSafe() {
    try {
      return GoogleMap(
        onMapCreated: (controller) {
          if (mounted) {
            _mapController = controller;
          }
        },
        initialCameraPosition: CameraPosition(
          target: _currentPosition,
          zoom: 15,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
        onCameraMove: (CameraPosition position) {
          // Evita problemas con setState durante animaciones
          if (mounted && _isTraining) {
            _currentPosition = position.target;
          }
        },
      );
    } catch (e) {
      print("Error creando GoogleMap: $e");
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Error al cargar el mapa',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
  }

  static Widget _buildLiveStat(String title, String value, String unit) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: kSecondaryTextColor, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: kPrimaryTextColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (unit.isNotEmpty)
          Text(
            unit,
            style: const TextStyle(color: kSecondaryTextColor, fontSize: 12),
          ),
      ],
    );
  }

  /// Card de "Resumen de la semana"
  Widget _buildWeekSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de la semana',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kPrimaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  Icons.timer_outlined,
                  _formatDurationHMS(_weeklyTimeSeconds),
                  'Tiempo total',
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                _buildSummaryItem(
                  Icons.speed_outlined,
                  '${_formatPace(_weeklyPace)} /km',
                  'Ritmo',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: kPrimaryGreen, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: kPrimaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: kSecondaryTextColor, fontSize: 12),
        ),
      ],
    );
  }

  /// Card de "Entrenamientos sugeridos"
  Widget _buildSuggestedWorkoutsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entrenamientos sugeridos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kPrimaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildWorkoutItem(
              Icons.electric_bolt,
              'Intervalos 5x1000m',
              '45 min • Alta intensidad',
            ),
            const Divider(height: 24),
            _buildWorkoutItem(
              Icons.directions_run,
              'Carrera larga',
              '90 min • Baja intensidad',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: kPrimaryGreen.withOpacity(0.1),
          child: Icon(icon, color: kPrimaryGreen),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: kPrimaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: kSecondaryTextColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text(
            'Iniciar',
            style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// Barra de Navegación Inferior
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedNavBarIndex,
      onTap: _onNavBarTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: kCardBackgroundColor,
      selectedItemColor: kPrimaryGreen,
      unselectedItemColor: kSecondaryTextColor,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Eventos',
        ),
        BottomNavigationBarItem(
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _selectedNavBarIndex == 2
                  ? kPrimaryGreen.withOpacity(0.1)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              color: _selectedNavBarIndex == 2
                  ? kPrimaryGreen
                  : kSecondaryTextColor,
            ),
          ),
          label: 'Perfil',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Comunidad',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.play_arrow),
          activeIcon: Icon(Icons.play_arrow_outlined),
          label: 'Entrenar',
        ),
      ],
    );
  }

  // --- VISTA DE PANTALLA COMPLETA ---
  Widget _buildTrainingFullScreen() {
    // --- Lógica de visualización de distancia (Metros vs Km) ---
    String distanceValue;
    String distanceUnit;

    if (_totalDistance < 1.0) {
      // Si es menos de 1 km, convertimos a metros y quitamos decimales
      // Ejemplo: 0.500 km -> 500 m
      distanceValue = (_totalDistance * 1000).toStringAsFixed(0);
      distanceUnit = "m";
    } else {
      // Si es 1 km o más, mostramos en km con 2 decimales
      // Ejemplo: 1.25 km
      distanceValue = _totalDistance.toStringAsFixed(2);
      distanceUnit = "km";
    }
    // -----------------------------------------------------------

    return Stack(
      children: [
        // 1. Mapa ocupando todo el fondo
        Positioned.fill(
          child: _isLoadingLocation
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom:
                        18, // Zoom bien cerca para ver el movimiento en metros
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId('route'),
                      points: _routePoints,
                      color: kPrimaryGreen,
                      width: 6,
                    ),
                  },
                ),
        ),

        // 2. Overlay superior (Gradiente)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, left: 20),
                child: Row(
                  children: [
                    // Indicador de grabación parpadeante (opcional, visual)
                    Icon(
                      Icons.fiber_manual_record,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Grabando ruta...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 3. Panel de control inferior flotante
        Positioned(
          bottom: 30,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Estadísticas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLiveStat("RITMO", _formatPace(_pace), "/km"),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                    _buildLiveStat("TIEMPO", _formatTime(_elapsedSeconds), ""),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),

                    // AQUÍ USAMOS LAS VARIABLES CALCULADAS ARRIBA
                    _buildLiveStat("DISTANCIA", distanceValue, distanceUnit),
                  ],
                ),
                const SizedBox(height: 20),
                // Botón de Parar Grande
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _stopTraining();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      "TERMINAR",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
