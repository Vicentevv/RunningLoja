import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../modelos/RunModel.dart';

class RunDetailScreen extends StatefulWidget {
  final RunModel run;

  const RunDetailScreen({Key? key, required this.run}) : super(key: key);

  @override
  _RunDetailScreenState createState() => _RunDetailScreenState();
}

class _RunDetailScreenState extends State<RunDetailScreen> {
  late GoogleMapController _mapController;
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _createPolylines();
  }

  void _createPolylines() {
    if (widget.run.routePoints.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: widget.run.routePoints,
          color: const Color(0xFFE67E22), // Orange
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (widget.run.routePoints.isNotEmpty) {
      // Small delay to ensure map is ready before animating
      Future.delayed(const Duration(milliseconds: 500), () {
        _fitBounds();
      });
    }
  }

  void _fitBounds() {
    if (widget.run.routePoints.isEmpty) return;

    final bounds = _boundsFromLatLngList(widget.run.routePoints);
    _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detalle de Carrera',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 1. MAPA
          SizedBox(
            height: 400,
            width: double.infinity,
            child: widget.run.routePoints.isEmpty
                ? const Center(child: Text("Sin datos de GPS"))
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: widget.run.routePoints.first,
                      zoom: 15,
                    ),
                    polylines: _polylines,
                    onMapCreated: _onMapCreated,
                    zoomControlsEnabled: true,
                    myLocationButtonEnabled: false,
                  ),
          ),

          // 2. DATOS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        icon: Icons.straighten,
                        label: 'Distancia',
                        value: '${widget.run.distanceKm.toStringAsFixed(2)} km',
                      ),
                      _StatItem(
                        icon: Icons.timer,
                        label: 'Tiempo',
                        value: _formatDuration(widget.run.durationSeconds),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        icon: Icons.speed,
                        label: 'Ritmo',
                        value:
                            '${_formatPace(widget.run.paceMinPerKm)} /km',
                      ),
                      _StatItem(
                        icon: Icons.local_fire_department,
                        label: 'Calorías',
                        value: '${widget.run.calories.toInt()} kcal',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatPace(double pace) {
    if (pace.isInfinite || pace.isNaN) return "0:00";
    final m = pace.floor();
    final s = ((pace - m) * 60).round();
    return "$m'${s.toString().padLeft(2, '0')}";
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 30, color: const Color(0xFF3A7D6E)),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
