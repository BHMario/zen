import 'package:zen/services/api_service.dart';

class AnalyticsService {
  /// Obtener tareas de la última semana desde API
  static Future<List<Map<String, dynamic>>> getWeeklyTasks(String userId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final allTasks = await ApiService.getTasks(userId: userId);
    return allTasks
        .where((task) {
          if (task['due_date'] == null) return false;
          final dueDate = DateTime.parse(task['due_date'] as String);
          return dueDate.isAfter(weekAgo) && dueDate.isBefore(now);
        })
        .toList();
  }

  /// Calcular cumplimiento de tareas por día de la semana
  static Future<Map<String, int>> getWeeklyTaskCompletion(String userId) async {
    final tasks = await getWeeklyTasks(userId);
    
    final Map<String, int> completion = {
      'Lunes': 0,
      'Martes': 0,
      'Miércoles': 0,
      'Jueves': 0,
      'Viernes': 0,
      'Sábado': 0,
      'Domingo': 0,
    };

    final Map<String, int> total = {
      'Lunes': 0,
      'Martes': 0,
      'Miércoles': 0,
      'Jueves': 0,
      'Viernes': 0,
      'Sábado': 0,
      'Domingo': 0,
    };

    final weekDays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

    for (final task in tasks) {
      final dueDate = DateTime.parse(task['due_date'] as String);
      final dayOfWeek = (dueDate.weekday % 7);
      final dayName = weekDays[dayOfWeek];

      total[dayName] = (total[dayName] ?? 0) + 1;

      final status = task['status'] as String?;
      if (status == 'completed') {
        completion[dayName] = (completion[dayName] ?? 0) + 1;
      }
    }

    // Convertir a porcentaje
    final result = <String, int>{};
    for (final day in weekDays) {
      if (total[day]! > 0) {
        result[day] = ((completion[day]! / total[day]!) * 100).round();
      } else {
        result[day] = 0;
      }
    }

    return result;
  }

  /// Obtener tiempo invertido por proyecto
  static Future<Map<String, double>> getTimeByProject(String userId) async {
    final projects = await ApiService.getProjects(userId: userId);
    final allTasks = await ApiService.getTasks(userId: userId);
    final Map<String, double> timeByProject = {};

    for (final project in projects) {
      final projectId = project['id'] as String;
      final projectName = project['name'] as String;
      
      final projectTasks = allTasks
          .where((task) => task['project_id'] == projectId)
          .toList();

      double totalHours = 0;
      for (final task in projectTasks) {
        final hours = task['hours'] as num?;
        if (hours != null) {
          totalHours += hours.toDouble();
        }
      }

      if (totalHours > 0) {
        timeByProject[projectName] = totalHours;
      }
    }

    return timeByProject;
  }

  /// Obtener porcentaje de hábitos cumplidos por día
  static Future<Map<String, int>> getHabitCompletion(String userId) async {
    final routines = await ApiService.getRoutines(userId: userId);
    
    final Map<String, int> completion = {
      'Lunes': 0,
      'Martes': 0,
      'Miércoles': 0,
      'Jueves': 0,
      'Viernes': 0,
      'Sábado': 0,
      'Domingo': 0,
    };

    final weekDays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

    // Simulación: en la práctica, necesitarías una tabla de completion history
    for (final routine in routines) {
      // Asignar aleatoriamente a días como simulación
      int dayIndex = routine['id'].toString().hashCode % 7;
      completion[weekDays[dayIndex]] = (completion[weekDays[dayIndex]]! + 20).clamp(0, 100);
    }

    return completion;
  }

  /// Calcular balance trabajo/vida personal basado en etiquetas
  static Future<Map<String, double>> getWorkLifeBalance(String userId) async {
    final tasks = await ApiService.getTasks(userId: userId);
    
    double workTasks = 0;
    double personalTasks = 0;

    for (final task in tasks) {
      final labels = task['labels'] is List 
          ? List<String>.from(task['labels'] as List)
          : [];
      final isWork = labels.any((label) => 
          label.toLowerCase().contains('trabajo') || 
          label.toLowerCase().contains('proyecto'));
      
      if (isWork) {
        workTasks += 1;
      } else {
        personalTasks += 1;
      }
    }

    final total = workTasks + personalTasks;
    if (total == 0) {
      return {'Trabajo': 50, 'Personal': 50};
    }

    return {
      'Trabajo': (workTasks / total) * 100,
      'Personal': (personalTasks / total) * 100,
    };
  }

  /// Calcular tendencia de productividad
  static Future<double> getProductivityTrend(String userId) async {
    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    final weekAgo = now.subtract(const Duration(days: 7));

    final allTasks = await ApiService.getTasks(userId: userId);

    // Tareas completadas hace 2 semanas a 1 semana
    final previousWeek = allTasks
        .where((task) {
          final dateStr = task['updated_at'];
          if (dateStr == null) return false;
          final date = DateTime.parse(dateStr as String);
          return date.isAfter(twoWeeksAgo) && 
                 date.isBefore(weekAgo) &&
                 task['status'] == 'completed';
        })
        .length;

    // Tareas completadas en la última semana
    final currentWeek = allTasks
        .where((task) {
          final dateStr = task['updated_at'];
          if (dateStr == null) return false;
          final date = DateTime.parse(dateStr as String);
          return date.isAfter(weekAgo) && 
                 date.isBefore(now) &&
                 task['status'] == 'completed';
        })
        .length;

    if (previousWeek == 0) return 0;
    
    final trend = ((currentWeek - previousWeek) / previousWeek) * 100;
    return trend;
  }

  /// Obtener total de tareas completadas
  static Future<int> getTotalCompletedTasks(String userId) async {
    final tasks = await ApiService.getTasks(userId: userId);
    return tasks.where((task) => task['status'] == 'completed').length;
  }

  /// Obtener total de tareas pendientes
  static Future<int> getTotalPendingTasks(String userId) async {
    final tasks = await ApiService.getTasks(userId: userId);
    return tasks.where((task) => task['status'] != 'completed').length;
  }

  /// Obtener streak actual de días productivos
  static Future<int> getProductivityStreak(String userId) async {
    final tasks = await ApiService.getTasks(userId: userId);
    
    int streak = 0;

    final completedByDate = <DateTime, int>{};
    for (final task in tasks) {
      if (task['status'] == 'completed') {
        final dateStr = task['updated_at'];
        if (dateStr != null) {
          final date = DateTime.parse(dateStr as String);
          final dateOnly = DateTime(date.year, date.month, date.day);
          completedByDate[dateOnly] = (completedByDate[dateOnly] ?? 0) + 1;
        }
      }
    }

    final sortedDates = completedByDate.keys.toList()..sort((a, b) => b.compareTo(a));
    
    DateTime? lastDate;
    for (final date in sortedDates) {
      if (lastDate == null || 
          lastDate.difference(date).inDays == 1) {
        streak++;
        lastDate = date;
      } else {
        break;
      }
    }

    return streak;
  }
}
