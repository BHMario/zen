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
          createdAt: DateTime.parse(goalData['created_at'] as String? ?? DateTime.now().toIso8601String()),
          updatedAt: DateTime.parse(goalData['updated_at'] as String? ?? DateTime.now().toIso8601String()),
          isCompleted: goalData['is_completed'] as bool? ?? false,
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
      if (_currentUserId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Convertir fechas al formato YYYY-MM-DD (sin tiempo)
      final startDateString = '${goal.startDate.year.toString().padLeft(4, '0')}-${goal.startDate.month.toString().padLeft(2, '0')}-${goal.startDate.day.toString().padLeft(2, '0')}';
      final targetDateString = '${goal.targetDate.year.toString().padLeft(4, '0')}-${goal.targetDate.month.toString().padLeft(2, '0')}-${goal.targetDate.day.toString().padLeft(2, '0')}';

      final result = await ApiService.createGoal({
        'user_id': _currentUserId!,
        'title': goal.title,
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

  List<Goal> getGoalsByDate(DateTime date) {
    // Normalizar la fecha a medianoche local
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Mostrar un objetivo SOLO si es el día de inicio o el día objetivo
    return _goals.where((goal) {
      if (goal.isCompleted) return false;
      
      final startDate = DateTime(goal.startDate.year, goal.startDate.month, goal.startDate.day);
      final targetDate = DateTime(goal.targetDate.year, goal.targetDate.month, goal.targetDate.day);

      final isStart = normalizedDate.isAtSameMomentAs(startDate);
      final isEnd = normalizedDate.isAtSameMomentAs(targetDate);

      return isStart || isEnd;
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
