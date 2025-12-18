import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String imageUrl;
  final String imagenBase64;
  final String categoria;
  final String tipo;
  final String nombre;
  final String fecha;
  final String ubicacion;
  final int inscritos;
  final String organizador;
  final String organizadorNombre;
  final String descripcion;
  final String distancia;
  final String maxParticipantes;
  final String email;
  final String telefono;
  final String incluye;
  final String requisitos;
  final List<String> participantes;

  EventModel({
    required this.id,
    required this.imageUrl,
    required this.imagenBase64,
    required this.categoria,
    required this.tipo,
    required this.nombre,
    required this.fecha,
    required this.ubicacion,
    required this.inscritos,
    required this.organizador,
    required this.organizadorNombre,
    required this.descripcion,
    required this.distancia,
    required this.maxParticipantes,
    required this.email,
    required this.telefono,
    required this.incluye,
    required this.requisitos,
    this.participantes = const [],
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Manejo seguro de los campos numéricos y de texto
    int parseInscritos() {
      final value = data['inscritos'];
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return EventModel(
      id: doc.id,
      imageUrl: data['imageUrl'] as String? ?? 'assets/default_event.jpg',
      imagenBase64: data['imagenBase64'] as String? ?? '',
      categoria: data['categoria'] as String? ?? 'Sin categoría',
      tipo: data['tipo'] as String? ?? 'Sin tipo',
      nombre: data['nombre'] as String? ?? 'Sin nombre',
      fecha: data['fecha'] as String? ?? '',
      ubicacion: data['ubicacion'] as String? ?? 'Sin ubicación',
      inscritos: parseInscritos(),
      organizador: data['organizador'] as String? ?? '',
      organizadorNombre: data['organizadorNombre'] as String? ?? 'Organizador',
      descripcion: data['descripcion'] as String? ?? '',
      distancia: data['distancia'] as String? ?? '0',
      maxParticipantes: data['maxParticipantes'] as String? ?? '0',
      email: data['email'] as String? ?? '',
      telefono: data['telefono'] as String? ?? '',
      incluye: data['incluye'] as String? ?? '',
      requisitos: data['requisitos'] as String? ?? '',
      participantes: data['participantes'] is List
          ? List<String>.from(data['participantes'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'imagenBase64': imagenBase64,
      'categoria': categoria,
      'tipo': tipo,
      'nombre': nombre,
      'fecha': fecha,
      'ubicacion': ubicacion,
      'inscritos': inscritos,
      'organizador': organizador,
      'organizadorNombre': organizadorNombre,
      'descripcion': descripcion,
      'distancia': distancia,
      'maxParticipantes': maxParticipantes,
      'email': email,
      'telefono': telefono,
      'incluye': incluye,
      'requisitos': requisitos,
      'participantes': participantes,
    };
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    int parseInscritos() {
      final value = json['inscritos'];
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return EventModel(
      id: json['id'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? 'assets/default_event.jpg',
      imagenBase64: json['imagenBase64'] as String? ?? '',
      categoria: json['categoria'] as String? ?? 'Sin categoría',
      tipo: json['tipo'] as String? ?? 'Sin tipo',
      nombre: json['nombre'] as String? ?? 'Sin nombre',
      fecha: json['fecha'] as String? ?? '',
      ubicacion: json['ubicacion'] as String? ?? 'Sin ubicación',
      inscritos: parseInscritos(),
      organizador: json['organizador'] as String? ?? '',
      organizadorNombre: json['organizadorNombre'] as String? ?? 'Organizador',
      descripcion: json['descripcion'] as String? ?? '',
      distancia: json['distancia'] as String? ?? '0',
      maxParticipantes: json['maxParticipantes'] as String? ?? '0',
      email: json['email'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
      incluye: json['incluye'] as String? ?? '',
      requisitos: json['requisitos'] as String? ?? '',
      participantes: json['participantes'] is List
          ? List<String>.from(json['participantes'])
          : [],
    );
  }

  EventModel copyWith({
    String? id,
    String? imageUrl,
    String? imagenBase64,
    String? categoria,
    String? tipo,
    String? nombre,
    String? fecha,
    String? ubicacion,
    int? inscritos,
    String? organizador,
    String? organizadorNombre,
    String? descripcion,
    String? distancia,
    String? maxParticipantes,
    String? email,
    String? telefono,
    String? incluye,
    String? requisitos,
    List<String>? participantes,
  }) {
    return EventModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      imagenBase64: imagenBase64 ?? this.imagenBase64,
      categoria: categoria ?? this.categoria,
      tipo: tipo ?? this.tipo,
      nombre: nombre ?? this.nombre,
      fecha: fecha ?? this.fecha,
      ubicacion: ubicacion ?? this.ubicacion,
      inscritos: inscritos ?? this.inscritos,
      organizador: organizador ?? this.organizador,
      organizadorNombre: organizadorNombre ?? this.organizadorNombre,
      descripcion: descripcion ?? this.descripcion,
      distancia: distancia ?? this.distancia,
      maxParticipantes: maxParticipantes ?? this.maxParticipantes,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      incluye: incluye ?? this.incluye,
      requisitos: requisitos ?? this.requisitos,
      participantes: participantes ?? this.participantes,
    );
  }
}

class UserModel {
  String uid;
  String fullName;
  String email;
  String avatarBase64; // ⬅️ NUEVO
  DateTime createdAt;

  double totalDistance;
  int totalRuns;
  String averagePace;
  int streakDays;

  String currentGoal;
  List<String> myEventIds;

  double height;
  double weight;
  String role;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.avatarBase64, // ⬅️ nuevo
    required this.createdAt,
    required this.totalDistance,
    required this.totalRuns,
    required this.averagePace,
    required this.streakDays,
    required this.currentGoal,
    required this.myEventIds,
    required this.height,
    required this.weight,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      "uid": uid,
      "fullName": fullName,
      "email": email,
      "avatarBase64": avatarBase64, // ⬅️ nuevo
      "createdAt": createdAt.toIso8601String(),
      "totalDistance": totalDistance,
      "totalRuns": totalRuns,
      "averagePace": averagePace,
      "streakDays": streakDays,
      "currentGoal": currentGoal,
      "myEventIds": myEventIds,
      "height": height,
      "weight": weight,
      "role": role,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json["uid"],
      fullName: json["fullName"],
      email: json["email"],
      avatarBase64: json["avatarBase64"] ?? "", // ⬅️ nuevo
      createdAt: DateTime.parse(json["createdAt"]),
      totalDistance: json["totalDistance"].toDouble(),
      totalRuns: json["totalRuns"],
      averagePace: json["averagePace"],
      streakDays: json["streakDays"],
      currentGoal: json["currentGoal"],
      myEventIds: List<String>.from(json["myEventIds"]),
      height: json["height"].toDouble(),
      weight: json["weight"].toDouble(),
      role: json["role"],
    );
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: data["uid"],
      fullName: data["fullName"],
      email: data["email"],
      avatarBase64: data["avatarBase64"] ?? "", // ⬅️ nuevo
      createdAt: DateTime.parse(data["createdAt"]),
      totalDistance: data["totalDistance"].toDouble(),
      totalRuns: data["totalRuns"],
      averagePace: data["averagePace"],
      streakDays: data["streakDays"],
      currentGoal: data["currentGoal"],
      myEventIds: List<String>.from(data["myEventIds"]),
      height: data["height"].toDouble(),
      weight: data["weight"].toDouble(),
      role: data["role"],
    );
  }

  // ⬅️ Método agregado: copyWith
  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? avatarBase64,
    DateTime? createdAt,
    double? totalDistance,
    int? totalRuns,
    String? averagePace,
    int? streakDays,
    String? currentGoal,
    List<String>? myEventIds,
    double? height,
    double? weight,
    String? role,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
      createdAt: createdAt ?? this.createdAt,
      totalDistance: totalDistance ?? this.totalDistance,
      totalRuns: totalRuns ?? this.totalRuns,
      averagePace: averagePace ?? this.averagePace,
      streakDays: streakDays ?? this.streakDays,
      currentGoal: currentGoal ?? this.currentGoal,
      myEventIds: myEventIds ?? this.myEventIds,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      role: role ?? this.role,
    );
  }
}
