import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/modelos/UserModel.dart';
import 'package:flutter_application_1/modelos/PostModel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePostModal extends StatefulWidget {
  const CreatePostModal({Key? key}) : super(key: key);

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  final TextEditingController _textController = TextEditingController();
  String imageBase64 = "";

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        imageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> publishPost() async {
    // --- Obtener usuario autenticado
    final userAuth = FirebaseAuth.instance.currentUser;
    if (userAuth == null) return;

    // --- Cargar info completa del usuario desde Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(userAuth.uid)
        .get();

    final user = UserModel.fromDocument(userDoc);

    // --- Crear documento
    final newDoc = FirebaseFirestore.instance.collection("posts").doc();

    final post = PostModel(
      id: newDoc.id,
      userId: user.uid,
      userName: user.fullName,
      userLevel: user.role,
      description: _textController.text.trim(),
      imageBase64: imageBase64,
      createdAt: DateTime.now(),
      likesCount: 0,
      commentsCount: 0,
    );

    // --- Guardar en Firestore
    await newDoc.set(post.toJson());

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Crear publicación",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              TextButton(
                onPressed: publishPost,
                child: const Text(
                  "Publicar",
                  style: TextStyle(color: Colors.green, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: "¿Qué deseas compartir hoy?",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.photo), onPressed: pickImage),
              if (imageBase64.isNotEmpty) const Text("Imagen seleccionada ✔️"),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
