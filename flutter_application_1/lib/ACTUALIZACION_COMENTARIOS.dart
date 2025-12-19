// ACTUALIZACIÓN: COMENTARIOS CON LIKES Y REGRESO A COMUNIDAD
// ============================================================

/**
 * CAMBIOS EN PostDetailScreen.dart:
 * 
 * 1. DISEÑO DE COMENTARIOS MEJORADO
 *    - Los comentarios ahora tienen un diseño más moderno similar a la imagen
 *    - Avatar del usuario más grande (radio: 20)
 *    - Nombre del usuario en negrita
 *    - Tiempo relativo (hace 1h, hace 3m, etc.)
 *    - Fondo blanco con borde gris sutil
 *    - Mayor espaciado entre comentarios
 * 
 * 2. LIKES EN COMENTARIOS
 *    - Cada comentario ahora puede recibir likes
 *    - Botón de corazón (vacío/lleno) interactivo
 *    - Contador de likes en tiempo real
 *    - Los likes se guardan en: posts/{postId}/comments/{commentId}/likes/{userId}
 * 
 * 3. REGRESO A COMUNIDAD
 *    - Después de agregar un comentario exitosamente:
 *      1. Se muestra el SnackBar "Comentario agregado"
 *      2. Se limpia el campo de texto
 *      3. Se regresa automáticamente a CommunityScreen (Navigator.pop)
 * 
 * MÉTODOS NUEVOS EN PostDetailScreen:
 *    - _buildCommentLikesRow(): Muestra likes del comentario
 *    - _toggleCommentLike(): Maneja agregar/remover like en comentario
 */

/**
 * CAMBIOS EN FirestoreService.dart:
 * 
 * NUEVOS MÉTODOS PARA LIKES EN COMENTARIOS:
 *    
 *    - addCommentLike(postId, commentId, userId)
 *      Agrega un like a un comentario
 *    
 *    - removeCommentLike(postId, commentId, userId)
 *      Remueve un like de un comentario
 *    
 *    - hasCommentLike(postId, commentId, userId)
 *      Verifica si el usuario actual le dio like al comentario
 *    
 *    - getCommentLikes(postId, commentId)
 *      Obtiene los likes de un comentario en tiempo real (Stream)
 */

/**
 * ESTRUCTURA DE DATOS EN FIREBASE:
 * 
 * posts/{postId}/
 *   ├── comments/{commentId}/
 *   │   ├── id
 *   │   ├── userId
 *   │   ├── userName
 *   │   ├── text
 *   │   ├── createdAt
 *   │   └── likes/{userId}  ← NUEVO
 *   │       ├── userId
 *   │       └── createdAt
 */

/**
 * FLUJO DE COMENTARIOS ACTUALIZADO:
 * 
 * 1. Usuario toca un post en CommunityScreen
 * 2. Se abre PostDetailScreen con los detalles del post
 * 3. Los comentarios se muestran con el nuevo diseño mejorado
 * 4. Usuario puede dar like a cualquier comentario
 * 5. Usuario escribe un comentario nuevo
 * 6. Al presionar enviar:
 *    - El comentario se guarda en Firebase
 *    - Se muestra notificación "Comentario agregado"
 *    - Se regresa automáticamente a CommunityScreen
 *    - El contador de comentarios se actualiza automáticamente
 */

/**
 * NOTAS IMPORTANTES:
 * - Los likes en comentarios se sincronizan en tiempo real
 * - El contador de likes se actualiza automáticamente con StreamBuilder
 * - La verificación de like es asincrónica y se actualiza al presionar
 * - El diseño sigue el mismo esquema de colores de la app
 */
