import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/training/controllers/training_controller.dart';
import '../features/training/screens/active_run_screen.dart';
import '../features/training/screens/post_run_summary.dart';
import '../features/training/screens/pre_run_screen.dart';
import 'LegacyTrainingScreen.dart'; // La pantalla original renombrada

// --- Constantes originales ---
const Color kPrimaryGreen = Color(0xFF3A7D6E);

class EntrenarScreen extends StatelessWidget {
  const EntrenarScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Proveer el Controller a todo el sub-árbol
    return ChangeNotifierProvider(
      create: (_) => TrainingController(),
      child: const _EntrenarContent(),
    );
  }
}

class _EntrenarContent extends StatelessWidget {
  const _EntrenarContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Escuchar el estado para decidir qué pantalla mostrar
    final trainingState = context.select<TrainingController, TrainingState>((c) => c.state);

    // --- DECISIÓN DE PANTALLA ---
    if (trainingState == TrainingState.running || trainingState == TrainingState.paused) {
      // 1. MODO ENTRENAMIENTO: Nueva Interfaz "Pro"
      return const ActiveRunScreen();
    } else if (trainingState == TrainingState.finished) {
      // 2. MODO RESUMEN: Nuevo Resumen
      return const PostRunSummary();
    } else if (trainingState == TrainingState.preparing) {
      // 3. MODO PREPARACIÓN: Selección de ruta y actividad (Con botón "back" manual)
      return PreRunScreen(); 
    } else {
      // 4. MODO IDLE: Pantalla Original "Legacy"
      // Esta pantalla tiene las gráficas, calendario y tabs que el usuario quiere conservar.
      return const LegacyTrainingScreen();
    }
  }
}
