import 'package:flutter/foundation.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/services/api_service.dart';

/// Servicio de sincronización de datos
/// Encargado de cargar todos los datos del usuario desde la API
/// Se ejecuta cuando el usuario inicia sesión
class DataSyncService {
  /// Sincronizar todos los datos del usuario después del login
  static Future<void> syncUserData({
    required String userId,
    required AuthProvider authProvider,
    required TaskProvider taskProvider,
    required ProjectProvider projectProvider,
    required ReminderProvider reminderProvider,
    required AnalyticsProvider analyticsProvider,
  }) async {
    try {
      debugPrint('🔄 Iniciando sincronización de datos para usuario: $userId');

      // Establecer el usuario actual en todos los providers
      taskProvider.setCurrentUser(userId);
      projectProvider.setCurrentUser(userId);
      reminderProvider.setCurrentUser(userId);

      // Cargar tareas desde API
      debugPrint('📋 Cargando tareas...');
      await taskProvider.loadUserTasks(userId);
      debugPrint('✅ Tareas cargadas: ${taskProvider.tasks.length}');

      // Cargar proyectos desde API
      debugPrint('📊 Cargando proyectos...');
      await projectProvider.loadUserProjects(userId);
      debugPrint('✅ Proyectos cargados: ${projectProvider.projects.length}');

      // Cargar recordatorios desde API
      debugPrint('⏰ Cargando recordatorios...');
      await reminderProvider.loadReminders(userId);
      debugPrint('✅ Recordatorios cargados: ${reminderProvider.reminders.length}');

      // Cargar analítica
      debugPrint('📈 Cargando analítica...');
      await analyticsProvider.loadAnalytics(userId);
      debugPrint('✅ Analítica cargada');

      debugPrint(
        '✨ Sincronización completada exitosamente',
      );
    } catch (e) {
      debugPrint('❌ Error durante sincronización: $e');
      rethrow;
    }
  }

  /// Obtener estadísticas de sincronización
  static Future<Map<String, int>> getSyncStats(String userId) async {
    try {
      final tasks = await ApiService.getTasks(userId: userId);
      
      return {
        'tasks': tasks.length,
        'projects': 0, // Se calcularía si se necesita desde API
        'completed_tasks': tasks
            .where((t) => t['status'] == 'completed')
            .length,
        'pending_tasks': tasks
            .where((t) => t['status'] != 'completed')
            .length,
      };
    } catch (e) {
      debugPrint('Error getting sync stats: $e');
      return {};
    }
  }

  /// Validar integridad de datos
  static Future<bool> validateDataIntegrity(String userId) async {
    try {
      // Obtener tareas desde API
      final tasks = await ApiService.getTasks(userId: userId);
      
      // Validar que todas las tareas pertenecen al usuario
      for (final task in tasks) {
        if (task['user_id'] != userId) {
          debugPrint('❌ Tarea huérfana encontrada: ${task['id']}');
          return false;
        }
      }

      // Obtener proyectos desde API
      final projects = await ApiService.getProjects(userId: userId);
      
      // Validar que todos los proyectos pertenecen al usuario
      for (final project in projects) {
        if (project['user_id'] != userId) {
          debugPrint('❌ Proyecto huérfano encontrado: ${project['id']}');
          return false;
        }
      }

      debugPrint('✅ Integridad de datos validada correctamente');
      return true;
    } catch (e) {
      debugPrint('Error validating data integrity: $e');
      return false;
    }
  }

  /// Realizar backup de datos
  static Future<Map<String, dynamic>> backupUserData(String userId) async {
    try {
      final tasks = await ApiService.getTasks(userId: userId);
      final projects = await ApiService.getProjects(userId: userId);

      return {
        'user_id': userId,
        'tasks': tasks,
        'projects': projects,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error backing up user data: $e');
      return {};
    }
  }

  /// Obtener información de sincronización para debugging
  static Future<String> getDebugInfo(String userId) async {
    final stats = await getSyncStats(userId);
    final isValid = await validateDataIntegrity(userId);
    
    return '''
═══════════════════════════════════════
📊 INFORMACIÓN DE SINCRONIZACIÓN
═══════════════════════════════════════
Usuario ID: $userId
Timestamp: ${DateTime.now()}

📈 ESTADÍSTICAS:
  • Tareas totales: ${stats['tasks'] ?? 0}
  • Tareas completadas: ${stats['completed_tasks'] ?? 0}
  • Tareas pendientes: ${stats['pending_tasks'] ?? 0}
  • Proyectos: ${stats['projects'] ?? 0}

🔍 VALIDACIÓN:
  • Integridad de datos: ${isValid ? '✅ OK' : '❌ ERROR'}

═══════════════════════════════════════
''';
  }
}
