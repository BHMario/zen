import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:zen/models/models.dart';
import 'package:zen/services/services.dart';

class RoutineProvider extends ChangeNotifier {
  List<Routine> _routines = [];
  bool _isLoading = false;
  String? _currentUserId;

  // Getters
  List<Routine> get routines => _routines;
  bool get isLoading => _isLoading;

  // Establecer usuario actual
  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  // Cargar todas las rutinas del usuario desde API
  Future<void> loadUserRoutines(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUserId = userId;
      final routineList = await ApiService.getRoutines(userId: userId);

      _routines = routineList.map((routineData) {
        List<DayOfWeek> daysOfWeek = [];
        if (routineData['days_of_week'] != null) {
          final daysData = routineData['days_of_week'];
          if (daysData is String) {
            try {
              final parsed = jsonDecode(daysData) as List;
              daysOfWeek = parsed.map((e) => DayOfWeek.values.byName(e as String)).toList();
            } catch (e) {
              daysOfWeek = [];
            }
          } else if (daysData is List) {
            daysOfWeek = daysData
                .map((e) => DayOfWeek.values.byName(e as String))
                .toList();
          }
        }

        List<String> steps = [];
        if (routineData['steps'] != null) {
          final stepsData = routineData['steps'];
          if (stepsData is String) {
            try {
              final parsed = jsonDecode(stepsData) as List;
              steps = parsed.map((e) => e.toString()).toList();
            } catch (_) {
              steps = [];
            }
          } else if (stepsData is List) {
            steps = stepsData.map((e) => e.toString()).toList();
          }
        }

        return Routine(
          id: routineData['id'] as String,
          name: routineData['title'] as String? ?? routineData['name'] as String,
          description: routineData['description'] as String?,
          frequency: _parseFrequency(routineData['frequency'] as String? ?? 'daily'),
          daysOfWeek: daysOfWeek,
          color: routineData['color'] as String? ?? '#8b5cf6',
          createdBy: userId,
          createdAt: DateTime.parse(routineData['created_at'] as String? ?? DateTime.now().toIso8601String()).toLocal(),
          updatedAt: DateTime.parse(routineData['updated_at'] as String? ?? DateTime.now().toIso8601String()).toLocal(),
          isActive: routineData['is_active'] == 1 || routineData['is_active'] == true,
          scheduleTime: routineData['schedule_time'] as String?,
          durationMinutes: (routineData['duration_minutes'] as num?)?.toInt(),
          repeatEveryDays: (routineData['repeat_every_days'] as num?)?.toInt() ?? 1,
          steps: steps,
        );
      }).toList();
      debugPrint('✅ ${_routines.length} rutinas cargadas desde API');
    } catch (e) {
      debugPrint('❌ Error loading routines from API: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Crear rutina en API
  Future<void> createRoutine(Routine routine) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Usuario no autenticado');
      }

      final result = await ApiService.createRoutine({
        'user_id': _currentUserId!,
        'title': routine.name,
        'description': routine.description,
        'frequency': routine.frequency.toString().split('.').last,
        'days_of_week': routine.daysOfWeek.map((e) => e.toString().split('.').last).toList(),
        'color': routine.color,
        'is_active': routine.isActive,
        'schedule_time': routine.scheduleTime,
        'duration_minutes': routine.durationMinutes,
        'created_by': routine.createdBy,
        'repeat_every_days': routine.repeatEveryDays,
        'steps': routine.steps,
      });

      if (!result.containsKey('error')) {
        _routines.add(routine);
        debugPrint('✅ Rutina creada en API: ${routine.name}');
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      debugPrint('❌ Error creating routine: $e');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  // Agregar rutina rápidamente
  Future<void> addRoutine({
    required String name,
    String? description,
    Frequency frequency = Frequency.daily,
    List<DayOfWeek> daysOfWeek = const [],
    String color = '#8b5cf6',
    String? userId,
    String? scheduleTime,
    int? durationMinutes,
    int repeatEveryDays = 1,
    List<String> steps = const [],
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

    final routine = Routine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      frequency: frequency,
      daysOfWeek: daysOfWeek,
      color: color,
      createdBy: actualUserId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      scheduleTime: scheduleTime,
      durationMinutes: durationMinutes,
      repeatEveryDays: repeatEveryDays,
      steps: steps,
    );

    await createRoutine(routine);
  }

  // Actualizar rutina existente
  Future<void> updateRoutine(Routine routine) async {
    try {
      final result = await ApiService.updateRoutine(routine.id, {
        'title': routine.name,
        'description': routine.description,
        'frequency': routine.frequency.toString().split('.').last,
        'color': routine.color,
        'is_active': routine.isActive,
        'schedule_time': routine.scheduleTime,
        'duration_minutes': routine.durationMinutes,
        'repeat_every_days': routine.repeatEveryDays,
        'steps': routine.steps,
      });

      if (!result.containsKey('error')) {
        final index = _routines.indexWhere((r) => r.id == routine.id);
        if (index != -1) {
          _routines[index] = routine.copyWith(updatedAt: DateTime.now());
        }
        debugPrint('✅ Rutina actualizada: ${routine.name}');
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      debugPrint('❌ Error actualizando rutina: $e');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  // Eliminar rutina
  Future<void> deleteRoutine(String routineId) async {
    try {
      final success = await ApiService.deleteRoutine(routineId);
      if (success) {
        _routines.removeWhere((r) => r.id == routineId);
        debugPrint('✅ Rutina eliminada: $routineId');
      } else {
        throw Exception('Error al eliminar la rutina');
      }
    } catch (e) {
      debugPrint('❌ Error eliminando rutina: $e');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  // Obtener rutinas por fecha (considera repeatEveryDays desde createdAt)
  List<Routine> getRoutinesByDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final dayOfWeek = DayOfWeek.values[date.weekday - 1];

    return _routines.where((routine) {
      if (!routine.isActive) return false;

      // Si usa repetición cada N días, aplicar esa lógica.
      if (routine.repeatEveryDays > 0) {
        final normalizedCreated = DateTime(
          routine.createdAt.year,
          routine.createdAt.month,
          routine.createdAt.day,
        );
        if (normalizedDate.isBefore(normalizedCreated)) return false;
        final dayDiff = normalizedDate.difference(normalizedCreated).inDays;
        return dayDiff % routine.repeatEveryDays == 0;
      }

      // Compatibilidad con lógica por frecuencia/días de semana.
      if (routine.daysOfWeek.isNotEmpty) {
        return routine.daysOfWeek.contains(dayOfWeek);
      }

      return routine.frequency == Frequency.daily;
    }).toList();
  }

  // Obtener rutinas activas
  List<Routine> getActiveRoutines() {
    return _routines.where((r) => r.isActive).toList();
  }

  // Limpiar todas las rutinas
  void clear() {
    _routines.clear();
  }

  // Parsear frecuencia
  Frequency _parseFrequency(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'weekly':
        return Frequency.weekly;
      case 'biweekly':
      case 'bi_weekly':
        return Frequency.biWeekly;
      case 'monthly':
        return Frequency.monthly;
      case 'daily':
      default:
        return Frequency.daily;
    }
  }
}
