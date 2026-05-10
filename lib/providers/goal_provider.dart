import 'package:flutter/foundation.dart';
import 'package:zen/models/models.dart';
import 'package:zen/services/services.dart';

class GoalProvider extends ChangeNotifier {
  List<Goal> _goals = [];
  bool _isLoading = false;
  String? _currentUserId;

  // Getters
  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;

  // Establecer usuario actual
  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  // Cargar todos los objetivos del usuario desde API
  Future<void> loadUserGoals(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUserId = userId;
      final goalList = await ApiService.getGoals(userId: userId);

      _goals = goalList.map((goalData) {
        // Parsear fechas YYYY-MM-DD sin conversión de zona horaria
        DateTime? parseDate(String? dateStr) {
          if (dateStr == null) return null;
          try {
            // Extraer solo la parte de la fecha (YYYY-MM-DD) para evitar desfases horarios
            final datePart = dateStr.contains('T') ? dateStr.split('T')[0] : dateStr.split(' ')[0];
            final parts = datePart.split('-');
            final year = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final day = int.parse(parts[2]);
            return DateTime(year, month, day);
          } catch (e) {
            debugPrint('❌ Error parsing goal date: $e');
            return null;
          }
        }

        return Goal(
          id: goalData['id'] as String,
          title: goalData['title'] as String,
          description: goalData['description'] as String?,
          category: _parseGoalCategory(goalData['category'] as String? ?? 'other'),
          timeframe: _parseGoalTimeframe(goalData['timeframe'] as String? ?? 'mediumTerm'),
          startDate: parseDate(goalData['start_date'] as String?) ?? DateTime.now(),
          targetDate: parseDate(goalData['target_date'] as String?) ?? DateTime.now().add(const Duration(days: 365)),
          targetValue: (goalData['target_value'] as num?)?.toDouble() ?? 1.0,
          currentValue: (goalData['current_value'] as num?)?.toDouble() ?? 0.0,
          unit: goalData['unit'] as String? ?? 'unidades',
          createdBy: userId,
          createdAt: DateTime.parse(goalData['created_at'] as String? ?? DateTime.now().toIso8601String()).toLocal(),
          updatedAt: DateTime.parse(goalData['updated_at'] as String? ?? DateTime.now().toIso8601String()).toLocal(),
          isCompleted: goalData['is_completed'] == 1 || goalData['is_completed'] == true,
            completedAt: goalData['completed_at'] != null
              ? DateTime.parse(goalData['completed_at'] as String)
              : null,
            completionAttachmentUrl:
              goalData['completion_attachment_url'] as String?,
            completionAttachmentType:
              goalData['completion_attachment_type'] as String?,
          color: goalData['color'] as String? ?? '#2A2A2A',
        );
      }).toList();
      debugPrint('✅ ${_goals.length} objetivos cargados desde API');
    } catch (e) {
      debugPrint('❌ Error loading goals from API: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Crear objetivo en API
  Future<void> createGoal(Goal goal) async {
    try {
      final userIdPayload = _currentUserId ?? goal.createdBy;
      if (userIdPayload.isEmpty) {
        throw Exception('Usuario no autenticado');
      }

      if (goal.title.trim().isEmpty) {
        throw Exception('El título del objetivo es obligatorio');
      }

      // Convertir fechas al formato YYYY-MM-DD (sin tiempo) para evitar desfases
      final startDateString = '${goal.startDate.year.toString().padLeft(4, '0')}-${goal.startDate.month.toString().padLeft(2, '0')}-${goal.startDate.day.toString().padLeft(2, '0')}';
      final targetDateString = '${goal.targetDate.year.toString().padLeft(4, '0')}-${goal.targetDate.month.toString().padLeft(2, '0')}-${goal.targetDate.day.toString().padLeft(2, '0')}';

      final result = await ApiService.createGoal({
        'user_id': userIdPayload,
        'title': goal.title.trim(),
        'description': goal.description,
        'category': goal.category.toString().split('.').last,
        'start_date': startDateString,
        'target_date': targetDateString,
        'target_value': goal.targetValue,
        'current_value': goal.currentValue,
        'unit': goal.unit,
        'timeframe': goal.timeframe.toString().split('.').last,
        'is_completed': goal.isCompleted,
        'color': goal.color,
        'created_by': goal.createdBy,
      });

      if (!result.containsKey('error')) {
        _goals.add(goal);
        debugPrint('✅ Objetivo creado en API: ${goal.title}');
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      debugPrint('❌ Error creating goal: $e');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  // Agregar objetivo rápidamente
  Future<void> addGoal({
    required String title,
    String? description,
    GoalCategory category = GoalCategory.other,
    GoalTimeframe timeframe = GoalTimeframe.mediumTerm,
    required DateTime startDate,
    required DateTime targetDate,
    double targetValue = 1.0,
    String unit = 'unidades',
    String color = '#2A2A2A',
    String? userId,
  }) async {
    String actualUserId;
    if (userId != null) {
      actualUserId = userId;
      _currentUserId = userId;
    } else if (_currentUserId != null) {
      actualUserId = _currentUserId!;
    } else {
      throw Exception('Usuario no autenticado. Por favor inicia sesión.');
    }

    final goal = Goal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      category: category,
      timeframe: timeframe,
      startDate: startDate,
      targetDate: targetDate,
      targetValue: targetValue,
      unit: unit,
      createdBy: actualUserId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      color: color,
    );

    await createGoal(goal);
  }

  List<Goal> getGoalsByDate(DateTime date) {
    return _goals.where((goal) {
      if (goal.isCompleted) return false;
      final d = DateTime(date.year, date.month, date.day);
      final start = DateTime(goal.startDate.year, goal.startDate.month, goal.startDate.day);
      final target = DateTime(goal.targetDate.year, goal.targetDate.month, goal.targetDate.day);
      return !d.isBefore(start) && !d.isAfter(target);
    }).toList();
  }

  // Obtener objetivos activos
  List<Goal> getActiveGoals() {
    return _goals.where((g) => !g.isCompleted).toList();
  }

  // Obtener objetivos completados
  List<Goal> getCompletedGoals() {
    return _goals.where((g) => g.isCompleted).toList();
  }

  // Actualizar objetivo
  Future<void> updateGoal(Goal goal) async {
    try {
      final result = await ApiService.updateGoal(goal.id, {
        'title': goal.title,
        'description': goal.description,
        'category': goal.category.toString().split('.').last,
        'target_date': goal.targetDate.toUtc().toIso8601String().split('T')[0],
        'target_value': goal.targetValue,
        'current_value': goal.currentValue,
        'unit': goal.unit,
        'color': goal.color,
        'is_completed': goal.isCompleted ? 1 : 0,
        'completed_at': goal.completedAt?.toIso8601String(),
        'completion_attachment_url': goal.completionAttachmentUrl,
        'completion_attachment_type': goal.completionAttachmentType,
      });
      if (!result.containsKey('error')) {
        final idx = _goals.indexWhere((g) => g.id == goal.id);
        if (idx != -1) _goals[idx] = goal.copyWith(updatedAt: DateTime.now());
        debugPrint('✅ Objetivo actualizado: ${goal.title}');
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      debugPrint('❌ Error actualizando objetivo: $e');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  // Eliminar objetivo
  Future<void> deleteGoal(String goalId) async {
    try {
      final success = await ApiService.deleteGoal(goalId);
      if (success) {
        _goals.removeWhere((g) => g.id == goalId);
        debugPrint('✅ Objetivo eliminado: $goalId');
      } else {
        throw Exception('Error eliminando objetivo');
      }
    } catch (e) {
      debugPrint('❌ Error eliminando objetivo: $e');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  // Marcar como completado / reactivar
  Future<void> toggleComplete(Goal goal) async {
    final willComplete = !goal.isCompleted;
    await updateGoal(
      goal.copyWith(
        isCompleted: willComplete,
        currentValue: willComplete ? goal.targetValue : goal.currentValue,
        completedAt: willComplete ? DateTime.now() : null,
        updatedAt: DateTime.now(),
      ),
    );
  }

  // Actualizar progreso
  Future<void> updateProgress(String goalId, double newValue) async {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx == -1) return;
    final goal = _goals[idx];
    final willComplete = newValue >= goal.targetValue;
    final updated = goal.copyWith(
      currentValue: newValue,
      isCompleted: willComplete,
      completedAt: willComplete
          ? (goal.completedAt ?? DateTime.now())
          : null,
      updatedAt: DateTime.now(),
    );
    await updateGoal(updated);
  }

  // Limpiar todos los objetivos
  void clear() {
    _goals.clear();
  }

  // Parsear categoría de objetivo
  GoalCategory _parseGoalCategory(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return GoalCategory.health;
      case 'career':
        return GoalCategory.career;
      case 'personal':
        return GoalCategory.personal;
      case 'finance':
        return GoalCategory.finance;
      case 'education':
        return GoalCategory.education;
      case 'relationships':
        return GoalCategory.relationships;
      case 'other':
      default:
        return GoalCategory.other;
    }
  }

  // Parsear marco de tiempo de objetivo
  GoalTimeframe _parseGoalTimeframe(String timeframe) {
    switch (timeframe.toLowerCase()) {
      case 'shortterm':
      case 'short_term':
        return GoalTimeframe.shortTerm;
      case 'mediumterm':
      case 'medium_term':
        return GoalTimeframe.mediumTerm;
      case 'longterm':
      case 'long_term':
        return GoalTimeframe.longTerm;
      default:
        return GoalTimeframe.mediumTerm;
    }
  }
}
