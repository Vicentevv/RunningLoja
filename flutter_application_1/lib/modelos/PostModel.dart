// modelos/PostModel.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String userLevel;
  final String description;
  final String imageBase64;
  final String userPhotoBase64;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool isVerified; // ⬅️ Nuevo campo

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userLevel,
    required this.description,
    required this.imageBase64,
    required this.userPhotoBase64,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    this.isVerified = false, // ⬅️ Valor por defecto
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "userId": userId,
      "userName": userName,
      "userLevel": userLevel,
      "description": description,
      "imageBase64": imageBase64,
      "userPhotoBase64": userPhotoBase64,
      "createdAt": createdAt.toIso8601String(),
      "likesCount": likesCount,
      "commentsCount": commentsCount,
      "isVerified": isVerified, // ⬅️ Mapeo
    };
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userLevel: json['userLevel'] ?? '',
      description: json['description'] ?? '',
      imageBase64: json['imageBase64'] ?? '',
      userPhotoBase64: json['userPhotoBase64'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      likesCount: (json['likesCount'] ?? 0) is int
          ? (json['likesCount'] ?? 0)
          : int.tryParse((json['likesCount'] ?? '0').toString()) ?? 0,
      commentsCount: (json['commentsCount'] ?? 0) is int
          ? (json['commentsCount'] ?? 0)
          : int.tryParse((json['commentsCount'] ?? '0').toString()) ?? 0,
      isVerified: json['isVerified'] ?? false, // ⬅️ Mapeo
    );
  }

  factory PostModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel.fromJson({...data, "id": doc.id});
  }
}
