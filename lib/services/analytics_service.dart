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
      final dueDateStr = task['due_date'] as String;
      final datePart = dueDateStr.contains('T') ? dueDateStr.split('T')[0] : dueDateStr.split(' ')[0];
      final parts = datePart.split('-');
      final dueDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final dayOfWeek = dueDate.weekday - 1; // 0=Lunes, 6=Domingo
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
        // Usar horas reales, con horas estimadas como respaldo
        final actual = task['actual_hours'] as num?;
        final estimated = task['estimated_hours'] as num?;
        final hours = actual ?? estimated;
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

  /// Obtener porcentaje de hábitos cumplidos por día (última semana)
  static Future<Map<String, int>> getHabitCompletion(String userId) async {
    final completions = await ApiService.getRoutineCompletions(userId: userId);

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekDays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

    final Map<String, int> completed = {
      for (final d in weekDays) d: 0,
    };
    final Map<String, int> total = {
      for (final d in weekDays) d: 0,
    };

    for (final c in completions) {
      final dateStr = c['completion_date'] as String?;
      if (dateStr == null) continue;
      final parts = dateStr.split('T')[0].split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      if (date.isBefore(weekAgo) || date.isAfter(now)) continue;

      final dayName = weekDays[date.weekday - 1];
      total[dayName] = (total[dayName] ?? 0) + 1;
      final isCompleted = c['completed'] == true || c['completed'] == 1;
      if (isCompleted) {
        completed[dayName] = (completed[dayName] ?? 0) + 1;
      }
    }

    final result = <String, int>{};
    for (final day in weekDays) {
      final t = total[day] ?? 0;
      result[day] = t > 0 ? ((completed[day]! / t) * 100).round() : 0;
    }
    return result;
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

    DateTime? parseDate(dynamic raw) {
      if (raw == null) return null;
      try { return DateTime.parse(raw as String); } catch (_) { return null; }
    }

    // Tareas completadas hace 2 semanas a 1 semana (usar completed_at, fallback updated_at)
    final previousWeek = allTasks
        .where((task) {
          if (task['status'] != 'completed') return false;
          final date = parseDate(task['completed_at']) ?? parseDate(task['updated_at']);
          if (date == null) return false;
          return date.isAfter(twoWeeksAgo) && date.isBefore(weekAgo);
        })
        .length;

    // Tareas completadas en la última semana
    final currentWeek = allTasks
        .where((task) {
          if (task['status'] != 'completed') return false;
          final date = parseDate(task['completed_at']) ?? parseDate(task['updated_at']);
          if (date == null) return false;
          return date.isAfter(weekAgo) && date.isBefore(now);
        })
        .length;

    if (previousWeek == 0) return currentWeek > 0 ? 100.0 : 0.0;

    return ((currentWeek - previousWeek) / previousWeek) * 100;
  }

  /// Obtener total de tareas completadas
  static Future<int> getTotalCompletedTasks(String userId) async {
    final tasks = await ApiService.getTasks(userId: userId);
    return tasks.where((task) => task['status'] == 'completed').length;
  }

  /// Obtener total de tareas pendientes (excluye canceladas)
  static Future<int> getTotalPendingTasks(String userId) async {
    final tasks = await ApiService.getTasks(userId: userId);
    return tasks
        .where((task) =>
            task['status'] == 'pending' || task['status'] == 'in_progress')
        .length;
  }

  /// Obtener streak actual de días productivos
  static Future<int> getProductivityStreak(String userId) async {
    final tasks = await ApiService.getTasks(userId: userId);
    
    int streak = 0;

    final completedByDate = <DateTime, int>{};
    for (final task in tasks) {
      if (task['status'] == 'completed') {
        // Preferir completed_at; caer en updated_at si no existe
        final dateStr = task['completed_at'] ?? task['updated_at'];
        if (dateStr != null) {
          try {
            final date = DateTime.parse(dateStr as String);
            final dateOnly = DateTime(date.year, date.month, date.day);
            completedByDate[dateOnly] = (completedByDate[dateOnly] ?? 0) + 1;
          } catch (_) {}
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
