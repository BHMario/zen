import 'package:flutter/foundation.dart';
import 'package:zen/models/models.dart';
import 'package:zen/services/services.dart';

class ReminderProvider extends ChangeNotifier {
  final List<Reminder> _reminders = [];
  String _currentUserId = '';

  List<Reminder> get reminders => _reminders;

  // Establecer usuario actual
  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  // Cargar todos los recordatorios del usuario desde la BD
  Future<void> loadReminders(String userId) async {
    try {
      debugPrint('🔄 Cargando recordatorios del usuario: $userId');
      _reminders.clear();
      
      _currentUserId = userId;
      
      final reminderList = await ApiService.getReminders(userId: userId);
      
      for (final reminderData in reminderList) {
        await addReminderFromDb(
          id: reminderData['id'] as String,
          itemId: reminderData['item_id'] as String?,
          type: reminderData['type'] as String? ?? 'task',
          dateTime: DateTime.parse(reminderData['date_time'] as String).toLocal(),
          frequency: reminderData['frequency'] as String? ?? 'once',
          message: reminderData['message'] as String?,
          isActive: _convertToBoolean(reminderData['is_active']),
          createdBy: reminderData['created_by'] as String?,
          createdAt: reminderData['created_at'] != null 
            ? DateTime.parse(reminderData['created_at'] as String).toLocal()
            : null,
          updatedAt: reminderData['updated_at'] != null 
            ? DateTime.parse(reminderData['updated_at'] as String).toLocal()
            : null,
        );
      }
      
      debugPrint('✅ ${_reminders.length} recordatorios cargados');
    } catch (e) {
      debugPrint('❌ Error loading reminders: $e');
    }
    notifyListeners();
  }

  // Obtener recordatorios por tipo de item
  List<Reminder> getRemindersByItemId(String itemId) {
    return _reminders.where((r) => r.itemId == itemId && r.isActive).toList();
  }

  // Obtener recordatorios para una fecha específica
  List<Reminder> getRemindersByDate(DateTime date) {
    return _reminders
        .where((r) {
          final reminderDate = DateTime(r.dateTime.year, r.dateTime.month, r.dateTime.day);
          final compareDate = DateTime(date.year, date.month, date.day);
          return reminderDate == compareDate && r.isActive;
        })
        .toList();
  }

  // Agregar recordatorio (con persistencia en API)
  Future<void> addReminder({
    required String itemId,
    required ReminderType type,
    required DateTime dateTime,
    ReminderFrequency frequency = ReminderFrequency.once,
    String? message,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Guardar en MySQL a través de API
      // Convertir a UTC para garantizar consistencia entre zonas horarias
      final result = await ApiService.createReminder(
        userId: _currentUserId!,
        itemId: itemId,
        type: type.toString().split('.').last,
        dateTime: dateTime.toUtc().toIso8601String(),
        frequency: frequency.toString().split('.').last,
        message: message,
        isActive: true,
        createdBy: _currentUserId,
      );

      if (!result.containsKey('error')) {
        final reminder = Reminder(
          id: result['reminderId'] ?? '',
          itemId: itemId,
          type: type,
          dateTime: dateTime,
          frequency: frequency,
          message: message,
          isActive: true,
          createdBy: _currentUserId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        _reminders.add(reminder);
        debugPrint('✅ Recordatorio creado en API');
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      debugPrint('❌ Error adding reminder: $e');
      rethrow;
    }
    notifyListeners();
  }

  // Actualizar recordatorio en API
  Future<void> updateReminder(
    String reminderId, {
    DateTime? dateTime,
    ReminderFrequency? frequency,
    String? message,
    bool? isActive,
  }) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == reminderId);
      if (index != -1) {
        final reminder = _reminders[index];
        
        // Actualizar en MySQL a través de API
        // Convertir a UTC para garantizar consistencia entre zonas horarias
        final result = await ApiService.updateReminder(
          reminderId: reminderId,
          updates: {
            'date_time': dateTime?.toUtc().toIso8601String() ?? reminder.dateTime.toUtc().toIso8601String(),
            'frequency': (frequency ?? reminder.frequency).toString().split('.').last,
            'message': message ?? reminder.message,
            'is_active': isActive ?? reminder.isActive,
          },
        );

        if (!result.containsKey('error')) {
          _reminders[index] = reminder.copyWith(
            dateTime: dateTime,
            frequency: frequency,
            message: message,
            isActive: isActive,
            updatedAt: DateTime.now(),
          );
          debugPrint('✅ Recordatorio actualizado en API');
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating reminder: $e');
      rethrow;
    }
  }

  // Eliminar recordatorio desde API
  Future<void> deleteReminder(String reminderId) async {
    try {
      // Eliminar de MySQL a través de API
      final success = await ApiService.deleteReminder(reminderId);

      if (success) {
        _reminders.removeWhere((r) => r.id == reminderId);
        debugPrint('✅ Recordatorio eliminado de API');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error deleting reminder: $e');
      rethrow;
    }
  }

  // Desactivar recordatorio
  Future<void> toggleReminder(String reminderId) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == reminderId);
      if (index != -1) {
        final reminder = _reminders[index];
        final newIsActive = !reminder.isActive;
        
        await updateReminder(
          reminderId,
          isActive: newIsActive,
        );
      }
    } catch (e) {
      debugPrint('Error toggling reminder: $e');
      rethrow;
    }
  }

  // Parsear tipo de recordatorio
  ReminderType _parseReminderType(String type) {
    switch (type.toLowerCase()) {
      case 'task':
        return ReminderType.task;
      case 'project':
        return ReminderType.project;
      case 'goal':
        return ReminderType.goal;
      case 'routine':
        return ReminderType.routine;
      default:
        return ReminderType.task;
    }
  }

  // Parsear frecuencia de recordatorio
  ReminderFrequency _parseReminderFrequency(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'once':
        return ReminderFrequency.once;
      case 'daily':
        return ReminderFrequency.daily;
      case 'weekly':
        return ReminderFrequency.weekly;
      case 'monthly':
        return ReminderFrequency.custom;
      default:
        return ReminderFrequency.once;
    }
  }

  // Cargar recordatorio desde BD (usado por SyncService)
  Future<void> addReminderFromDb({
    required String id,
    String? itemId,
    required String type,
    required DateTime dateTime,
    required String frequency,
    String? message,
    bool isActive = true,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final reminder = Reminder(
      id: id,
      itemId: itemId ?? '',
      type: _parseReminderType(type),
      dateTime: dateTime,
      frequency: _parseReminderFrequency(frequency),
      message: message,
      isActive: isActive,
      createdBy: createdBy ?? _currentUserId ?? 'system',
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
    _reminders.add(reminder);
  }

  // Convertir valor de BD (int 0/1 o bool) a boolean
  bool _convertToBoolean(dynamic value) {
    if (value is bool) {
      return value;
    } else if (value is int) {
      return value != 0;
    } else if (value == null) {
      return true;
    } else {
      return true;
    }
  }

  // Limpiar todos los recordatorios
  void clear() {
    _reminders.clear();
  }
}
