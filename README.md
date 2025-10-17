# RunningLoja
Metodología Scrum - App Mobile Running Loja
Product Backlog
Lista de requisitos:
Requisitos funcionales:
Pantalla de carga
Login y Registro
Pantalla de bienvenida
Pantalla de noticias y carreras
Pantalla Perfil (Edad, peso, altura, categoria, sexo )
Pantalla de registro para un evento
Pantalla para registrar eventos (Carreras, talleres, campañas)
Pantalla de tus entrenamientos
Pantalla donde ver tu ruta/entrenamiento (Strava)
Pantalla para comunidades
Reproductor de Música (Tipo waze)
Guardar el registro de tu ruta mientras estás offline, y que la registre cuando ya tengas conexión.
Permiso de ubicación
Únete a mi ruta
Agregar notificaciones de la ruta
Ver usuarios de tu comunidad en el mapa
Consejos de como hacer un buen calentamiento
Tener un calendario donde se vea tus racha de entrenamiento
ÉPICA 1: Registro, inicio de sesión y carga inicial
HU01 – Pantalla de carga (Splash screen)
Como usuario, quiero ver una pantalla de carga con el logo de la aplicación para identificar la app al iniciarla.
Criterios de aceptación:
Se muestra el logo mientras se carga la app.
Dura unos segundos y redirige a login o bienvenida.
HU02 – Registro y login
Como corredor, quiero registrarme o iniciar sesión con mis credenciales o cuenta de Google para acceder a mis datos personales y entrenamientos.
Criterios de aceptación:
Permitir registro con correo y Google.
Validar datos antes de crear cuenta.
Guardar sesión iniciada.

HU03 – Pantalla de bienvenida
Como usuario, quiero ver una pantalla de bienvenida después de iniciar sesión para sentir una experiencia personalizada.
Criterios de aceptación:
Mostrar saludo personalizado (nombre).
Botones de acceso rápido a secciones principales.
ÉPICA 2: Entrenamientos y rutas
HU04 – Ver tus entrenamientos
Como corredor, quiero visualizar mi historial de entrenamientos para hacer seguimiento de mis progresos.
Criterios de aceptación:
Mostrar lista con fecha, distancia, tiempo y ritmo.
Permitir filtrar por semana o mes.
HU05 – Registrar una ruta/entrenamiento (GPS estilo Strava)
Como corredor, quiero registrar mi entrenamiento en tiempo real mediante GPS para analizar mi distancia, velocidad y ruta.
Criterios de aceptación:
Mostrar mapa y métricas en vivo.
Guardar el recorrido terminado.
Mostrar resumen al finalizar.
HU06 – Guardar rutas offline
Como corredor, quiero guardar mi entrenamiento cuando no tengo conexión y que se sincronice automáticamente cuando vuelva a estar en línea.
Criterios de aceptación:
Detectar la pérdida de conexión.
Guardar datos localmente.
Sincronizar cuando haya internet.
HU07 – Permiso de ubicación
Como usuario, quiero que la app solicite permisos de ubicación para registrar mis rutas correctamente.
Criterios de aceptación:
Mostrar solicitud al abrir app por primera vez.
No iniciar entrenamiento sin permiso concedido.

HU08 – Unirse a una ruta
Como corredor, quiero unirme a la ruta de otro usuario para compartir el recorrido y entrenar en grupo.
Criterios de aceptación:
Permitir aceptar invitación o enlace.
Mostrar participantes en el mapa.
HU09 – Notificaciones de la ruta
Como corredor, quiero recibir notificaciones durante mi ruta (por distancia o ritmo) para mantenerme informado sin mirar la pantalla.
Criterios de aceptación:
Activar o desactivar alertas.
Mostrar notificaciones por voz o vibración.
HU10 – Calendario y racha de entrenamiento
Como corredor, quiero ver un calendario con mis entrenamientos para visualizar mis rachas de actividad.
Criterios de aceptación:
Mostrar los días con entrenamientos marcados.
Calcular y mostrar rachas consecutivas.
ÉPICA 3: Comunidad y social
HU11 – Comunidades
Como usuario, quiero unirme o crear comunidades de corredores para compartir experiencias y rutas.
Criterios de aceptación:
Permitir crear o unirse a una comunidad.
Mostrar lista de miembros.
HU12 – Ver usuarios de mi comunidad en el mapa
Como corredor, quiero ver a otros miembros de mi comunidad en el mapa para saber quiénes están corriendo cerca.
Criterios de aceptación:
Mostrar iconos de usuarios conectados.
Actualizar ubicación en tiempo real.
HU13 – Noticias y carreras
Como corredor, quiero ver noticias y próximas carreras para mantenerme informado del mundo running.
Criterios de aceptación:
Mostrar lista de publicaciones o banners.
Permitir abrir detalles del evento.
ÉPICA 4: Eventos y registro
HU14 – Registro a un evento
Como corredor, quiero inscribirme a carreras o eventos según mi categoría para participar oficialmente.
Criterios de aceptación:
Mostrar formulario de inscripción.
Validar categoría, edad y sexo.
Confirmar registro.
HU15 – Crear/Registrar eventos (organizador)
Como organizador, quiero crear eventos (carreras, talleres o campañas) para que los corredores puedan inscribirse.
Criterios de aceptación:
Formulario con nombre, tipo, fecha y ubicación.
Publicación visible para todos los usuarios.
ÉPICA 5: Motivación y bienestar
HU16 – Reproductor de música (tipo Waze)
Como corredor, quiero escuchar música integrada durante mi entrenamiento sin salir de la app.
Criterios de aceptación:
Control de pausa, siguiente y volumen.
No interrumpir el registro de la ruta.
HU17 – Consejos de calentamiento
Como corredor, quiero ver consejos y rutinas de calentamiento antes de correr para evitar lesiones.
Criterios de aceptación:
Mostrar sección con tips o videos.
Actualizar contenido periódicamente.
ÉPICA 6: Perfil y personalización
HU18 – Perfil del usuario
Como corredor, quiero editar mi perfil con mi edad, peso, altura, sexo y categoría para personalizar mi experiencia.
Criterios de aceptación:
Permitir editar y guardar campos.
Mostrar resumen con datos y progreso.
Requisitos no funcionales:
Mensajes motivacionales
Recordatorios y notificaciones para ir a entrenar

Requisitos no funcionales
Rendimiento y eficiencia 
RNF01: La sincronización de datos offline debe realizarse automáticamente cuando se recupere la conexión
RNF02: El registro de rutas GPS no debe tener un desfase mayor a 5 metros respecto a la ubicación real.
RNF03:.
RNF04: El consumo de batería durante el registro de una ruta no debe superar el 10% por hora de uso continuo.
RNF05: Las pantallas deben responder en menos de 2 segundos al interactuar (toques, scroll, botones, etc.).
Seguridad y privacidad 
RNF06: Las contraseñas de los usuarios deben almacenarse cifradas (por ejemplo, con bcrypt o similar).
RNF07: Los datos personales (peso, edad, altura, etc.) deben estar protegidos bajo políticas de privacidad y acceso restringido.
RNF08: La app debe solicitar permisos explícitos para acceder a la ubicación y al almacenamiento.

Usabilidad y diseño 
RNF11: La interfaz debe ser intuitiva y accesible para todo tipo de usuario, con íconos claros y textos legibles.
RNF12: Los colores y tipografía deben mantener coherencia en todas las pantallas.
RNF13: La app debe permitir su uso tanto en modo claro como en modo oscuro.
RNF15: El reproductor de música debe permitir control sin necesidad de salir de la pantalla de entrenamiento.
Conectividad y disponibilidad 
RNF16: La aplicación debe funcionar correctamente en modo offline, permitiendo registrar rutas y sincronizarlas cuando haya conexión.RNF17: La app debe adaptarse a diferentes tipos de conexión (WiFi, 4G, 5G).
RNF18: Los datos del usuario deben sincronizarse con el servidor cada vez que se detecte una conexión activa.
RNF19: La aplicación debe poder usarse en Android.
Fiabilidad y mantenimiento 
RNF20: El sistema debe garantizar un 99% de disponibilidad durante el uso normal.
RNF21: En caso de cierre inesperado, la app debe guardar el progreso actual del entrenamiento.
RNF23: Las actualizaciones deben poder realizarse sin pérdida de datos del usuario.



Compatibilidad 
RNF24: La aplicación debe ser compatible con Android 8.0+
RNF25: Debe adaptarse correctamente a diferentes resoluciones de pantalla (smartphones y tablets).
Notificaciones y comunicación 
RNF27: Las notificaciones deben enviarse en menos de 5 segundos después de un evento importante (inicio de carrera, recordatorio, inscripción).
RNF28: Deben incluir vibración o sonido, configurables por el usuario.
RNF29: El usuario debe poder activar o desactivar las notificaciones desde el perfil.
Escalabilidad y backend 
RNF30: El backend debe soportar al menos 10.000 usuarios concurrentes en la primera versión.
RNF31: Los endpoints de la API deben responder en menos de 500 ms en promedio.
RNF32: La base de datos debe estar optimizada para registrar y consultar rutas geográficas sin ralentización.
Localización e internacionalización 
RNF33: La aplicación debe permitir cambiar el idioma entre al menos español e inglés.
RNF34: Los formatos de distancia y tiempo deben adaptarse a la región del usuario (km/millas).


Accesibilidad 
RNF35: Los textos deben tener un contraste mínimo de 4.5:1 según las normas WCAG.
RNF36: La app debe ser compatible con lectores de pantalla y gestos accesibles.
RNF37: Debe permitir ajustar el tamaño de fuente según las preferencias del sistema.

























Sprint Planning
Sprint
Duración estimada
Objetivo principal del Sprint
Historias de Usuario / Requisitos
Entregables esperados
Sprint 1
21 oct – 10 nov 2025
Configurar entorno, estructura base del proyecto y pantallas iniciales.
HU01 – Pantalla de cargaHU02 – Login y RegistroHU03 – Pantalla de bienvenida
App base creada (estructura del proyecto, navegación, splash, login funcional con Firebase/Google).
Sprint 2
11 nov – 1 dic 2025
Implementar perfil del usuario y gestión básica de datos.
HU18 – Perfil del usuarioRNF06–RNF10 (seguridad y autenticación)RNF11–RNF12 (usabilidad)
Pantalla de perfil funcional, almacenamiento seguro de datos personales, validación y diseño coherente.
Sprint 3
2 dic – 22 dic 2025
Registro y visualización de entrenamientos.
HU04 – Ver tus entrenamientosHU05 – Registrar ruta/entrenamiento (GPS)HU07 – Permiso de ubicación
Módulo de entrenamientos implementado (registro GPS, historial, métricas, ubicación funcional).
Sprint 4
23 dic – 12 ene 2026
Sincronización offline y calendario de rachas.
HU06 – Guardar rutas offlineHU10 – Calendario y racha de entrenamientoRNF16–RNF18 (conectividad y disponibilidad)
Funcionalidad offline completa, calendario visible y sincronización automática.
Sprint 5
13 ene – 2 feb 2026
Comunidad y mapa interactivo.
HU11 – ComunidadesHU12 – Ver usuarios en el mapaRNF24–RNF26 (compatibilidad)
Pantalla de comunidades activa, usuarios visibles en el mapa, comunicación entre miembros.
Sprint 6
3 feb – 23 feb 2026
Noticias, eventos e inscripciones.
HU13 – Noticias y carrerasHU14 – Registro a eventoHU15 – Crear eventos
Módulo de eventos completo (listar, inscribirse, crear y ver detalles).
Sprint 7
24 feb – 16 mar 2026
Integrar música y motivación.
HU16 – Reproductor de músicaHU17 – Consejos de calentamientoRNF27–RNF29 (notificaciones)
Reproductor integrado con controles, notificaciones activas y consejos de salud visibles.
Sprint 8
17 mar – 6 abr 2026
Optimización, pruebas y mejoras visuales.
RNF01–RNF05 (rendimiento)RNF20–RNF23 (fiabilidad)RNF35–RNF37 (accesibilidad)
App optimizada, pruebas de usabilidad y accesibilidad aprobadas, diseño final mejorado.
Sprint 9
7 abr – 27 abr 2026
Integración con APIs externas y finalización del backend.
RNF26 – Google Fit / Apple HealthRNF30–RNF32 (escalabilidad y backend)
Integración con APIs externas y backend estable.
Sprint 10
28 abr – 18 may 2026
Revisión general, documentación y despliegue final.
Revisión de todas las HUs y RNFs
Documentación técnica, manual de usuario y app lista para publicación.





Desarrollo (Daily Scrum)


Sprint Review


Sprint Retrospective


