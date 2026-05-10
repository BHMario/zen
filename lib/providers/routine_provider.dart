import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:zen/models/models.dart';
import 'package:zen/services/services.dart';

class RoutineCompletionData {
  final bool isCompleted;
  final String? attachmentUrl;
  final String? attachmentType;
  final DateTime? completedAt;

  const RoutineCompletionData({
    required this.isCompleted,
    this.attachmentUrl,
    this.attachmentType,
    this.completedAt,
  });
}

class RoutineProvider extends ChangeNotifier {
  List<Routine> _routines = [];
  final Map<String, Map<String, RoutineCompletionData>>
      _completedDatesByRoutine = {};
  bool _isLoading = false;
  String? _currentUserId;

  // Getters
  List<Routine> get routines => _routines;
  bool get isLoading => _isLoading;

  String _normalizeDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool isRoutineCompletedOnDate(String routineId, DateTime date) {
    final normalized = _normalizeDate(date);
    return _completedDatesByRoutine[routineId]?[normalized]?.isCompleted ?? false;
  }

  RoutineCompletionData? getRoutineCompletionForDate(String routineId, DateTime date) {
    final normalized = _normalizeDate(date);
    return _completedDatesByRoutine[routineId]?[normalized];
  }

  int getCompletedCountForWeek(DateTime referenceDate) {
    final current = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    final weekStart = current.subtract(Duration(days: current.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    int count = 0;
    for (final datesByDay in _completedDatesByRoutine.values) {
      for (final entry in datesByDay.entries) {
        if (!entry.value.isCompleted) continue;
        final dateString = entry.key;
        final parts = dateString.split('-');
        if (parts.length != 3) continue;
        final d = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        if (!d.isBefore(weekStart) && !d.isAfter(weekEnd)) {
          count++;
        }
      }
    }
    return count;
  }

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
          color: routineData['color'] as String? ?? '#2A2A2A',
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

      final completions = await ApiService.getRoutineCompletions(userId: userId);
      _completedDatesByRoutine.clear();
      for (final c in completions) {
        final routineId = c['routine_id']?.toString();
        final rawDate = c['completion_date']?.toString();
        if (routineId == null || rawDate == null) continue;
        final normalized = rawDate.contains('T') ? rawDate.split('T')[0] : rawDate;
        final completedAt = c['completed_at'] != null
            ? DateTime.tryParse(c['completed_at'].toString())
            : null;
        _completedDatesByRoutine
            .putIfAbsent(routineId, () => <String, RoutineCompletionData>{})[normalized] =
            RoutineCompletionData(
          isCompleted: true,
          attachmentUrl: c['attachment_url'] as String?,
          attachmentType: c['attachment_type'] as String?,
          completedAt: completedAt,
        );
      }

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
    String color = '#2A2A2A',
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

  Future<void> setRoutineCompletedForDate({
    required String routineId,
    required DateTime date,
    required bool completed,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    if (_currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    final ok = await ApiService.setRoutineCompletion(
      routineId: routineId,
      userId: _currentUserId!,
      completionDate: date,
      completed: completed,
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
    );

    if (!ok) {
      throw Exception('No se pudo actualizar el estado de la rutina');
    }

    final normalized = _normalizeDate(date);
    final map = _completedDatesByRoutine
        .putIfAbsent(routineId, () => <String, RoutineCompletionData>{});
    if (completed) {
      map[normalized] = RoutineCompletionData(
        isCompleted: true,
        attachmentUrl: attachmentUrl,
        attachmentType: attachmentType,
        completedAt: DateTime.now(),
      );
    } else {
      map.remove(normalized);
    }

    notifyListeners();
  }

  Future<void> toggleRoutineCompletedForDate(String routineId, DateTime date) async {
    final current = isRoutineCompletedOnDate(routineId, date);
    await setRoutineCompletedForDate(
      routineId: routineId,
      date: date,
      completed: !current,
    );
  }

  // Limpiar todas las rutinas
  void clear() {
    _routines.clear();
    _completedDatesByRoutine.clear();
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
