import 'package:flutter/material.dart';
import 'package:flutter_application_1/pantallas/EventosScreen.dart';

class EventDetailScreen extends StatelessWidget {
  final EventInfo event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return 'Sin fecha';
    try {
      final date = DateTime.parse(isoDate);
      final months = [
        'ene',
        'feb',
        'mar',
        'abr',
        'may',
        'jun',
        'jul',
        'ago',
        'sep',
        'oct',
        'nov',
        'dic',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate.split('T').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  _buildStatsSection(),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: "Descripción",
                    child: Text(
                      event.descripcion.isEmpty
                          ? "Sin descripción"
                          : event.descripcion,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: "Requisitos",
                    child: event.requisitos.isEmpty
                        ? const Text(
                            "No hay requisitos específicos",
                            style: TextStyle(color: Colors.black54),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: event.requisitos.split(',').map((r) {
                              final text = r.trim();
                              if (text.isEmpty) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF27AE60),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        text,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: "Incluye",
                    child: event.incluye.isEmpty
                        ? const Text(
                            "No incluye nada especificado",
                            style: TextStyle(color: Colors.black54),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: event.incluye.split(',').map((i) {
                              final text = i.trim();
                              if (text.isEmpty) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.card_giftcard,
                                      color: Color(0xFFE67E22),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        text,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          _buildBottomButton(context),
        ],
      ),
    );
  }

  // ==================== HEADER ======================
  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: event.imageUrl.startsWith('assets/')
              ? Image.asset(event.imageUrl, fit: BoxFit.cover)
              : Image.network(
                  event.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ),
        ),
        Container(
          height: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _circleButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
        Positioned(bottom: 20, left: 20, right: 20, child: _headerInfo()),
      ],
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _headerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _tag(event.categoria, const Color(0xFF27AE60)),
            const SizedBox(width: 10),
            _tag(event.tipo, const Color(0xFF3498DB)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          event.nombre,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              _formatDate(event.fecha),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.location_on, size: 18, color: Colors.white70),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                event.ubicacion,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // ==================== STATS ======================
  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.route, "Distancia", "${event.distancia} km"),
          _statItem(
            Icons.people_alt,
            "Inscritos",
            "${event.inscritos}/${event.maxParticipantes}",
          ),
          _statItem(Icons.confirmation_number, "Cupo", event.maxParticipantes),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 28, color: const Color(0xFF2D8E6F)),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ==================== CONTACTO ======================
  Widget _buildContactCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Contacto del organizador",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF2D8E6F)),
              const SizedBox(width: 12),
              Text(event.organizador, style: const TextStyle(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone, color: Color(0xFF2D8E6F)),
              const SizedBox(width: 12),
              Text(event.telefono, style: const TextStyle(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.email, color: Color(0xFF2D8E6F)),
              const SizedBox(width: 12),
              Text(event.email, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== INFO CARD ======================
  Widget _buildInfoCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ==================== BOTTOM BUTTON ======================
  Widget _buildBottomButton(BuildContext context) {
    final maxParticipantesInt = int.tryParse(event.maxParticipantes) ?? 0;
    final yaLleno = event.inscritos >= maxParticipantesInt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: yaLleno ? Colors.grey : const Color(0xFF2D8E6F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 3,
          ),
          onPressed: yaLleno
              ? null
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("¡Te has inscrito al evento!"),
                      backgroundColor: Color(0xFF2D8E6F),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
          child: Text(
            yaLleno ? "Cupo lleno" : "Inscribirme ahora",
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
