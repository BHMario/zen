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
        return Goal(
          id: goalData['id'] as String,
          title: goalData['title'] as String,
          description: goalData['description'] as String?,
          category: _parseGoalCategory(goalData['category'] as String? ?? 'other'),
          timeframe: _parseGoalTimeframe(goalData['timeframe'] as String? ?? 'mediumTerm'),
          startDate: goalData['start_date'] != null
              ? DateTime.parse(goalData['start_date'] as String).toLocal()
              : DateTime.now(),
          targetDate: goalData['target_date'] != null
              ? DateTime.parse(goalData['target_date'] as String).toLocal()
              : DateTime.now().add(const Duration(days: 365)),
          targetValue: (goalData['target_value'] as num?)?.toDouble() ?? 1.0,
          currentValue: (goalData['current_value'] as num?)?.toDouble() ?? 0.0,
          unit: goalData['unit'] as String? ?? 'unidades',
          createdBy: userId,
          createdAt: DateTime.parse(goalData['created_at'] as String? ?? DateTime.now().toIso8601String()).toLocal(),
          updatedAt: DateTime.parse(goalData['updated_at'] as String? ?? DateTime.now().toIso8601String()).toLocal(),
          isCompleted: goalData['is_completed'] == 1 || goalData['is_completed'] == true,
          color: goalData['color'] as String? ?? '#ec4899',
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

      final result = await ApiService.createGoal({
        'user_id': userIdPayload,
        'title': goal.title.trim(),
        'description': goal.description,
        'category': goal.category.toString().split('.').last,
        'start_date': goal.startDate.toUtc().toIso8601String(),
        'target_date': goal.targetDate.toUtc().toIso8601String(),
        'target_value': goal.targetValue,
        'current_value': goal.currentValue,
        'unit': goal.unit,
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
    String color = '#ec4899',
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

  // Obtener objetivos por fecha (para calendario)
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
    await updateGoal(goal.copyWith(isCompleted: !goal.isCompleted, updatedAt: DateTime.now()));
  }

  // Actualizar progreso
  Future<void> updateProgress(String goalId, double newValue) async {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx == -1) return;
    final goal = _goals[idx];
    final updated = goal.copyWith(
      currentValue: newValue,
      isCompleted: newValue >= goal.targetValue,
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
