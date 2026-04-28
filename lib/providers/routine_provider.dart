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
          isActive: routineData['is_active'] as bool? ?? true,
          scheduleTime: routineData['schedule_time'] as String?,
          durationMinutes: routineData['duration_minutes'] as int?,
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
        'created_by': routine.createdBy,
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
    );

    await createRoutine(routine);
  }

  // Obtener rutinas por fecha (para calendario)
  List<Routine> getRoutinesByDate(DateTime date) {
    return _routines
        .where((routine) => routine.isActive)
        .toList();
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
