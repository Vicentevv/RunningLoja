// ESTRUCTURA DE LA BASE DE DATOS FIREBASE
// ======================================================

/**
 * COLECCIÓN: posts
 * 
 * posts/
 *   ├── {postId}
 *   │   ├── id: string
 *   │   ├── userId: string
 *   │   ├── userName: string
 *   │   ├── userLevel: string (ej: "Principiante")
 *   │   ├── description: string
 *   │   ├── imageBase64: string
 *   │   ├── createdAt: timestamp
 *   │   ├── likesCount: number (incrementado/decrementado con cada like)
 *   │   ├── commentsCount: number (incrementado/decrementado con cada comentario)
 *   │   │
 *   │   ├── comments/ (subcollection)
 *   │   │   ├── {commentId}
 *   │   │   │   ├── id: string
 *   │   │   │   ├── userId: string
 *   │   │   │   ├── userName: string
 *   │   │   │   ├── text: string
 *   │   │   │   └── createdAt: timestamp
 *   │   │
 *   │   └── likes/ (subcollection)
 *   │       ├── {userId}
 *   │       │   ├── userId: string
 *   │       │   └── createdAt: timestamp
 */

// ======================================================
// FUNCIONALIDADES IMPLEMENTADAS
// ======================================================

/**
 * 1. PANTALLA PostDetailScreen
 *    - Muestra el detalle completo del post
 *    - Permite dar like/unlike (botón de corazón)
 *    - Muestra contador de likes actualizado en tiempo real
 *    - Muestra contador de comentarios
 *    - Muestra lista de comentarios en tiempo real
 *    - Campo para agregar nuevos comentarios
 *    - Los comentarios se guardan en: posts/{postId}/comments/{commentId}
 *    - Los likes se guardan en: posts/{postId}/likes/{userId}
 */

/**
 * 2. MÉTODOS EN FirestoreService
 *    - addComment(): Agrega comentario y actualiza commentsCount
 *    - getComments(): Obtiene comentarios en tiempo real
 *    - deleteComment(): Elimina comentario y actualiza commentsCount
 *    - addLike(): Agrega like y actualiza likesCount
 *    - removeLike(): Remueve like y actualiza likesCount
 *    - getLikes(): Obtiene likes en tiempo real
 *    - hasUserLikedPost(): Verifica si el usuario actual liked el post
 */

/**
 * 3. NAVEGACIÓN EN CommunityScreen
 *    - Toque en un post abre PostDetailScreen
 *    - Se pasa el postId y el objeto PostModel completo
 *    - La pantalla de detalle es totalmente interactiva
 */

/**
 * 4. DISEÑO
 *    - Sigue el mismo diseño que el resto de la app
 *    - Usa los mismos colores (kPrimaryGreen, kCardBackgroundColor, etc.)
 *    - Interfaz intuitiva y responsiva
 *    - BottomSheet para el campo de comentarios
 */

// ======================================================
// REGLAS DE FIRESTORE RECOMENDADAS
// ======================================================

/**
 * Para que todo funcione correctamente, configura las reglas en Firebase:
 * 
 * rules_version = '2';
 * service cloud.firestore {
 *   match /databases/{database}/documents {
 *     // Usuarios pueden leer/escribir sus propios documentos
 *     match /users/{userId} {
 *       allow read, write: if request.auth.uid == userId;
 *     }
 *     
 *     // Posts pueden ser leídos por todos
 *     match /posts/{postId} {
 *       allow read: if true;
 *       allow write: if request.auth != null;
 *       
 *       // Comentarios
 *       match /comments/{commentId} {
 *         allow read: if true;
 *         allow create: if request.auth != null;
 *         allow delete: if request.auth.uid == resource.data.userId;
 *       }
 *       
 *       // Likes
 *       match /likes/{userId} {
 *         allow read: if true;
 *         allow write: if request.auth.uid == userId;
 *       }
 *     }
 *   }
 * }
 */
