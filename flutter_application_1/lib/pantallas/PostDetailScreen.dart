import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../modelos/PostModel.dart';
import '../modelos/CommentModel.dart';
import '../servicios/FirestoreService.dart';

// --- Colores ---
const Color kPrimaryGreen = Color(0xFF3A7D6E);
const Color kLightGreenBackground = Color(0xFFF0F5F3);
const Color kCardBackgroundColor = Colors.white;
const Color kPrimaryTextColor = Color(0xFF333333);
const Color kSecondaryTextColor = Color(0xFF666666);
const Color kAccentOrange = Color(0xFFE67E22);

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final PostModel post;

  const PostDetailScreen({Key? key, required this.postId, required this.post})
    : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  late User? _currentUser;
  bool _isLikedByMe = false;
  int _currentLikesCount = 0;
  bool _isVerified = false;
  String _currentUserName = 'Usuario';

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _currentLikesCount = widget.post.likesCount;
    _checkIfLiked();
    _loadCurrentUserProfile();
  }

  Future<void> _loadCurrentUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _isVerified = doc.data()?['isVerified'] ?? false;
          _currentUserName = doc.data()?['fullName'] ?? 'Usuario';
        });
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkIfLiked() async {
    if (_currentUser == null) return;

    try {
      final likeDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('likes')
          .doc(_currentUser!.uid)
          .get();

      setState(() {
        _isLikedByMe = likeDoc.exists;
      });
    } catch (e) {
      print('Error al verificar like: $e');
    }
  }

  Future<void> _toggleLike() async {
    if (_currentUser == null) return;

    try {
      if (_isLikedByMe) {
        await _firestoreService.removeLike(widget.postId, _currentUser!.uid);
        setState(() {
          _isLikedByMe = false;
          _currentLikesCount--;
        });
      } else {
        await _firestoreService.addLike(widget.postId, _currentUser!.uid);
        setState(() {
          _isLikedByMe = true;
          _currentLikesCount++;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar like: $e')));
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty || _currentUser == null) return;

    try {
      await _firestoreService.addComment(
        postId: widget.postId,
        userId: _currentUser!.uid,
        userName: _currentUserName, // ⬅️ Usamos nombre real de Firestore
        text: _commentController.text,
        isVerified: _isVerified, 
      );

      _commentController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comentario agregado')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar comentario: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightGreenBackground,
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        title: const Text(
          'Detalle del Post',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // POST CARD COMPLETA
            _buildPostDetailCard(),

            // COMENTARIOS SECTION
            _buildCommentsSection(),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: _buildCommentInputSheet(),
    );
  }

  Widget _buildPostDetailCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER DEL POST
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey.withOpacity(0.3),
                backgroundImage: widget.post.userPhotoBase64.isNotEmpty
                    ? MemoryImage(base64Decode(widget.post.userPhotoBase64))
                    : null,
                child: widget.post.userPhotoBase64.isEmpty
                    ? Text(
                        widget.post.userName.isNotEmpty
                            ? widget.post.userName.substring(0, 1).toUpperCase()
                            : "?",
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post.userName,
                      style: const TextStyle(
                        color: kPrimaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "${widget.post.userLevel} • hace poco",
                      style: const TextStyle(
                        color: kSecondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // DESCRIPCIÓN
          Text(
            widget.post.description,
            style: const TextStyle(
              color: kPrimaryTextColor,
              fontSize: 16,
              height: 1.4,
            ),
          ),

          // IMAGEN SI EXISTE
          if (widget.post.imageBase64.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  base64Decode(widget.post.imageBase64),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // LIKES Y COMMENTS
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _toggleLike,
                child: Icon(
                  _isLikedByMe ? Icons.favorite : Icons.favorite_border,
                  color: _isLikedByMe ? Colors.red : kSecondaryTextColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "$_currentLikesCount",
                style: const TextStyle(
                  color: kSecondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 24),
              const Icon(
                Icons.chat_bubble_outline,
                color: kSecondaryTextColor,
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                "${widget.post.commentsCount}",
                style: const TextStyle(
                  color: kSecondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comentarios (${widget.post.commentsCount})',
            style: const TextStyle(
              color: kPrimaryTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .doc(widget.postId)
                .collection('comments')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Aún no hay comentarios. ¡Sé el primero!',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                );
              }

              final comments = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final commentData =
                      comments[index].data() as Map<String, dynamic>;
                  final comment = CommentModel.fromJson(commentData);

                  return _buildCommentCard(comment);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(CommentModel comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar y nombre
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.teal.withOpacity(0.2),
                child: Text(
                  comment.userName.isNotEmpty
                      ? comment.userName.substring(0, 1).toUpperCase()
                      : "?",
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              comment.userName,
                              style: const TextStyle(
                                color: kPrimaryTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (comment.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: Colors.blueAccent, size: 14),
                          ],
                        ],
                      ),
                    Text(
                      _formatDateTime(comment.createdAt),
                      style: const TextStyle(
                        color: kSecondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Texto del comentario
          Text(
            comment.text,
            style: const TextStyle(
              color: kPrimaryTextColor,
              fontSize: 14,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 10),

          // Like del comentario
          _buildCommentLikesRow(comment.id),
        ],
      ),
    );
  }

  Widget _buildCommentLikesRow(String commentId) {
    return StreamBuilder<int>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .collection('likes')
          .snapshots()
          .map((snapshot) => snapshot.docs.length),
      builder: (context, likesSnapshot) {
        final likesCount = likesSnapshot.data ?? 0;

        return FutureBuilder<bool>(
          future: _firestoreService.hasCommentLike(
            widget.postId,
            commentId,
            _currentUser?.uid ?? '',
          ),
          builder: (context, likeStatus) {
            final isLiked = likeStatus.data ?? false;

            return GestureDetector(
              onTap: () => _toggleCommentLike(commentId, isLiked),
              child: Row(
                children: [
                  Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : kSecondaryTextColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$likesCount',
                    style: const TextStyle(
                      color: kSecondaryTextColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleCommentLike(String commentId, bool isLiked) async {
    if (_currentUser == null) return;

    try {
      if (isLiked) {
        await _firestoreService.removeCommentLike(
          widget.postId,
          commentId,
          _currentUser!.uid,
        );
      } else {
        await _firestoreService.addCommentLike(
          widget.postId,
          commentId,
          _currentUser!.uid,
        );
      }
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar like: $e')));
    }
  }

  Widget _buildCommentInputSheet() {
    return Container(
      color: kCardBackgroundColor,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Escribe un comentario...',
              hintStyle: const TextStyle(color: kSecondaryTextColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: kPrimaryGreen),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: kPrimaryGreen),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: GestureDetector(
                onTap: _addComment,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: kPrimaryGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'hace ${difference.inHours}h';
    } else {
      return 'hace ${difference.inDays}d';
    }
  }
}
