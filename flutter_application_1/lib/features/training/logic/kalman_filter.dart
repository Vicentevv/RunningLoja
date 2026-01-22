class KalmanLatLong {
  final double minAccuracy;
  late double _lat;
  late double _lng;
  late double _variance; // P

  KalmanLatLong(this.minAccuracy) {
    _variance = -1;
  }

  /// Establece el estado inicial
  void setState(double lat, double lng, double accuracy, int timestampMs) {
    _lat = lat;
    _lng = lng;
    _variance = accuracy * accuracy;
  }

  /// Procesa una nueva coordenada y devuelve la suavizada (o null si es inválida)
  /// speed: metros por segundo
  List<double>? process(
    double lat,
    double lng,
    double accuracy,
    int timestampMs,
    double speed,
  ) {
    if (accuracy > minAccuracy) {
      // Ignorar actualizaciones con muy mala precisión (valor de accuracy alto = malo)
      return null;
    }

    if (_variance < 0) {
      // Primera lectura
      setState(lat, lng, accuracy, timestampMs);
      return [lat, lng];
    }

    // Predicción
    // Asumimos que la posición se mantiene (modelo simple), pero la incertidumbre (varianza) aumenta con el tiempo/movimiento
    // Q: Varianza del proceso. Mayor velocidad -> mayor incertidumbre.
    // double timeStep = 1; // Simplificación: asumimos updates ~1s o proporcional
    double qMetresPerSecond = speed < 0
        ? 3.0
        : speed; // Si speed es desconocido, asumimos 3m/s

    // Q tiene que escalar con el tiempo. Si pasó mucho tiempo, la incertidumbre es mayor.
    // _variance = _variance + Q
    // Aproximación simple:
    double varianceProcess = qMetresPerSecond * qMetresPerSecond;

    _variance += varianceProcess;

    // Corrección (Kalman Gain)
    // K = P / (P + R)
    // R: Varianza de la medición (accuracy^2)
    double r = accuracy * accuracy;
    double k = _variance / (_variance + r);

    // Update State
    // X = X + K * (Z - X)
    _lat += k * (lat - _lat);
    _lng += k * (lng - _lng);

    // Update Variance
    // P = (1 - K) * P
    _variance = (1 - k) * _variance;

    return [_lat, _lng];
  }
}
