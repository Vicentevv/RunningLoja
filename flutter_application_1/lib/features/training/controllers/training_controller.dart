import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../pantallas/local_route_manager.dart'; // Import para guardado offline
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../../../../modelos/RunModel.dart'; // Importar modelo actualizado
import 'dart:math' show cos, sqrt, asin;
import '../logic/kalman_filter.dart'; // Importar Filtro Kalman

enum TrainingState { idle, preparing, running, paused, finished }

class TrainingController extends ChangeNotifier {
  // --- Dependencias ---
  final Location _location = Location();

  // --- Estado ---
  TrainingState _state = TrainingState.idle;
  TrainingState get state => _state;

  // --- Métodos de Transición ---
  void prepareTraining() {
    _state = TrainingState.preparing;
    notifyListeners();
    // Obtener ubicación inicial para centrar el mapa
    _location.getLocation().then((loc) {
      if (loc.latitude != null && loc.longitude != null) {
        // Usamos _pathPoints temporalmente para guardar la posición actual sin iniciar ruta
        // O mejor, añadimos un campo _currentPositionCache
        // Para no romper lógica, solo invocamos notifyListeners si queremos que la UI se actualice
        // Pero PreRunScreen usa 'currentPosition' que saca de _pathPoints.last
        // ASI QUE: Vamos a hackearlo un poco o añadir un campo dedicado.
        // Mejor opción: Añadir un campo _userLocationForMap
      }
    });
    // MEJOR AÚN: Iniciar un listener de baja frecuencia solo para UI
    _startPreRunLocationUpdates();
  }

  void cancelPreparation() {
    _state = TrainingState.idle;
    _locationSubscription?.cancel(); // Cancelar listener de pre-run
    _pathPoints.clear(); // Limpiar si había algo
    notifyListeners();
  }

  // Listener ligero para el mapa antes de empezar
  void _startPreRunLocationUpdates() async {
    try {
      // Nos aseguramos permisos
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      _locationSubscription?.cancel();
      _locationSubscription = _location.onLocationChanged.listen((loc) {
        if (_state != TrainingState.preparing) return;
        if (loc.latitude != null && loc.longitude != null) {
          // Actualizamos una variable interna o usamos _pathPoints con 1 solo punto que se reemplaza
          // Usaremos _pathPoints hack: Limpiar y poner 1.
          // ESTO ES SOLO VISUAL. Al dar Start, se limpia todo en startTraining().
          _pathPoints.clear();
          _pathPoints.add(LatLng(loc.latitude!, loc.longitude!));
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint("Error pre-run location: $e");
    }
  }

  // --- Datos de Sesión ---
  int _secondsElapsed = 0;
  double _distanceKm = 0.0;
  double _currentPace = 0.0; // min/km
  final List<LatLng> _pathPoints = [];

  // Getters
  int get secondsElapsed => _secondsElapsed;
  double get distanceKm => _distanceKm;
  double get currentPace => _currentPace;
  List<LatLng> get pathPoints => List.unmodifiable(_pathPoints);
  LatLng? get currentPosition =>
      _pathPoints.isNotEmpty ? _pathPoints.last : null;

  // --- Rutas Fantasmas (Para seguir) ---
  List<LatLng>? _ghostRoute;
  List<LatLng>? get ghostRoute => _ghostRoute;

  // --- Internos (Timer & Streams) ---
  Timer? _timer;
  StreamSubscription<LocationData>? _locationSubscription;
  LatLng? _lastRecordedPosition;

  // Filtro de Kalman
  final _kalmanFilter = KalmanLatLong(
    25.0,
  ); // 25 metros como peor precisión aceptable
  int _lastTimestamp = 0;

  // --- Configuración ---
  bool _isDisposed = false;

  // Constructor
  TrainingController() {
    _initLocation();
  }

  // Inicializar permisos y configuración de Location
  Future<void> _initLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) return;
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) return;
    }

    // Configuración inicial (Baja potencia para Pre-Run)
    await _location.changeSettings(
      accuracy: LocationAccuracy.balanced,
      interval: 5000,
    );
  }

  // Cargar una ruta para seguir (Ghost Route)
  void loadRouteToFollow(List<LatLng> points) {
    if (points.isNotEmpty) {
      _ghostRoute = points;
      notifyListeners();
    }
  }

  // --- INICIAR ENTRENAMIENTO ---
  Future<void> startTraining() async {
    if (_state == TrainingState.running) return;

    // 1. Configuración High Precision y Segundo Plano
    try {
      await _location.enableBackgroundMode(
        enable: true,
      ); // <--- BACKGROUND MODE

      await _location.changeSettings(
        accuracy: LocationAccuracy.navigation, // MÁXIMA PRECISIÓN
        interval: 1000, // Cada 1 segundo
        distanceFilter: 0, // Notificar cualquier movimiento
      );
    } catch (e) {
      debugPrint("Error cambiando settings de location: $e");
    }

    // 2. Reset si es fresh start
    if (_state == TrainingState.idle || _state == TrainingState.finished) {
      _secondsElapsed = 0;
      _distanceKm = 0.0;
      _currentPace = 0.0;
      _pathPoints.clear();
      _lastRecordedPosition = null;
      _lastTimestamp = DateTime.now().millisecondsSinceEpoch;

      // Intentar obtener posición inicial inmediata
      try {
        final loc = await _location.getLocation();
        if (loc.latitude != null && loc.longitude != null) {
          // Inicializar filtro
          _kalmanFilter.setState(
            loc.latitude!,
            loc.longitude!,
            loc.accuracy ?? 10,
            _lastTimestamp,
          );

          final pos = LatLng(loc.latitude!, loc.longitude!);
          _pathPoints.add(pos);
          _lastRecordedPosition = pos;
        }
      } catch (_) {}
    }

    _state = TrainingState.running;
    notifyListeners();

    // 3. Iniciar Timer
    _startTimer();

    // 4. Iniciar GPS Stream
    _locationSubscription?.cancel();
    _locationSubscription = _location.onLocationChanged.listen(
      _handleLocationUpdate,
    );
  }

  // --- PAUSAR ---
  void pauseTraining() {
    _state = TrainingState.paused;
    _timer?.cancel();
    // No cancelamos locationSubscription del todo si queremos mantener el GPS caliente,
    // pero para horrar batería y evitar puntos locos en pausa, a veces es mejor cancelar.
    // Sin embargo, enableBackgroundMode sigue activo.
    _locationSubscription?.cancel();
    notifyListeners();
  }

  // --- RESUMIR ---
  void resumeTraining() {
    startTraining(); // Reutiliza la lógica de inicio (reactiva streams)
  }

  // --- TERMINAR ---
  Future<void> stopTraining() async {
    _state = TrainingState.finished;
    _timer?.cancel();
    _locationSubscription?.cancel();

    // Restaurar GPS a modo balanceado y quitar background
    try {
      await _location.enableBackgroundMode(enable: false);
      await _location.changeSettings(
        accuracy: LocationAccuracy.balanced,
        interval: 10000,
      );
    } catch (_) {}

    notifyListeners();
  }

  // --- MANEJO DE LOCACIÓN (CORE) ---
  void _handleLocationUpdate(LocationData data) {
    if (_state != TrainingState.running) return;
    if (data.latitude == null || data.longitude == null) return;

    // 1. Filtrado básico por precisión bruta (opcional, el Kalman ya pondera)
    if (data.accuracy != null && data.accuracy! > 30) {
      // Si la precisión es terrible (>30m), descartar
      return;
    }

    final int now = DateTime.now().millisecondsSinceEpoch;
    final double speed =
        data.speed ?? 0.0; // velocidad en m/s reportada por GPS

    // 2. APLICAR FILTRO DE KALMAN
    final smoothed = _kalmanFilter.process(
      data.latitude!,
      data.longitude!,
      data.accuracy ?? 10.0,
      now,
      speed,
    );

    if (smoothed == null) return; // Filtro rechazó el punto

    final newPos = LatLng(smoothed[0], smoothed[1]);

    // Calcular distancia
    if (_lastRecordedPosition != null) {
      final distIncrement = _calculateDistance(_lastRecordedPosition!, newPos);

      // Filtro anti-ruido (mínimo movimiento para contar)
      // Con Kalman podemos ser un poco más relajados, o mantener 2m
      if (distIncrement > 0.002) {
        // > 2 metros
        _distanceKm += distIncrement;
        _pathPoints.add(newPos);
        _lastRecordedPosition = newPos;

        // Actualizar ritmo
        _updatePace();
      }
    } else {
      _pathPoints.add(newPos);
      _lastRecordedPosition = newPos;
    }

    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsElapsed++;
      notifyListeners();
    });
  }

  void _updatePace() {
    if (_distanceKm > 0.05) {
      // Solo calcular ritmo después de 50 metros
      // Ritmo actual instantáneo es muy volátil.
      // Mejor: Ritmo medio de los últimos X segundos o distancia.
      // Por simplicidad mantenemos el promedio global por ahora,
      // o implementamos una media simple.

      double globalPace = (_secondsElapsed / 60.0) / _distanceKm;

      // Suavizado exponencial para ritmo actual
      if (_currentPace == 0) {
        _currentPace = globalPace;
      } else {
        // Valoramos más el histórico para evitar saltos bruscos
        _currentPace = _currentPace * 0.9 + globalPace * 0.1;
      }
    }
  }

  // --- GUARDAR SESIÓN (Offline + Online) ---
  Future<void> saveRun(String uid) async {
    // UMBRAL DE PRUEBA: 5 metros (0.005 km) en lugar de 50m
    if (_distanceKm < 0.005) {
      debugPrint(
        "Distancia muy corta para guardar ($_distanceKm km). Mínimo 0.005 km",
      );
      return;
    }

    try {
      // 1. PRIMERO: Guardar copia local (Backup de seguridad)
      debugPrint("Intentando guardar backup local...");
      await LocalRouteManager.saveRoute(
        points: _pathPoints,
        imageBytes:
            null, // No guardamos imagen por ahora para ahorrar espacio/errores
        distanceKm: _distanceKm,
        durationSeconds: _secondsElapsed,
      );

      // 2. SEGUNDO: Intentar guardar en Firebase con nuevo modelo
      debugPrint("Intentando sincronizar con Firebase...");

      final sessionModel = RunModel(
        id: "", // Se autogenera en Firestore
        distanceKm: double.parse(_distanceKm.toStringAsFixed(3)),
        durationSeconds: _secondsElapsed,
        paceMinPerKm: double.parse(_currentPace.toStringAsFixed(3)),
        calories: _calculateCalories(
          _distanceKm,
          _secondsElapsed,
        ), // Implementar o usar 0 por ahora
        date: DateTime.now(),
        routePoints: _pathPoints,
      );

      final db = FirebaseFirestore.instance;
      // Guardar en subcolección 'sessions'
      await db
          .collection("users")
          .doc(uid)
          .collection("sessions")
          .add(sessionModel.toJson());

      // Actualizar totales en documento de usuario
      await db.collection("users").doc(uid).set({
        'total_distance': FieldValue.increment(_distanceKm),
        'total_time_seconds': FieldValue.increment(_secondsElapsed),
        'session_count': FieldValue.increment(1),
      }, SetOptions(merge: true));

      debugPrint("Guardado completado (Local + Firebase Queue)");
    } catch (e) {
      debugPrint("Error saving run: $e");
      // Si falla Firebase por algo crítico, al menos ya tenemos el local
      rethrow;
    }
  }

  // Estimación básica de calorías (METs * Kg * horas)
  // Usamos valor promedio: 70kg, MET 9 (correr suave)
  double _calculateCalories(double dist, int seconds) {
    if (dist <= 0 || seconds <= 0) return 0.0;
    // Fórmula simplificada: 1km corre ~ 60-70 kcal
    return dist * 65.0;
  }

  // --- RESET (Para Post-Run) ---
  void reset() {
    _state = TrainingState.idle;
    _distanceKm = 0.0;
    _secondsElapsed = 0;
    _currentPace = 0.0;
    _pathPoints.clear();
    _ghostRoute = null;
    _lastRecordedPosition = null;
    notifyListeners();
  }

  // Haversine Formula (Distancia en Km)
  double _calculateDistance(LatLng p1, LatLng p2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a =
        0.5 -
        c((p2.latitude - p1.latitude) * p) / 2 +
        c(p1.latitude * p) *
            c(p2.latitude * p) *
            (1 - c((p2.longitude - p1.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }
}
