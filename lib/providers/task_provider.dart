import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:zen/models/models.dart';
import 'package:zen/services/services.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = false;
  String? _currentUserId;

  // Getters
  List<Task> get tasks => _tasks;
  List<Task> get filteredTasks => _filteredTasks;
  bool get isLoading => _isLoading;

  // Establecer usuario actual (se llama cuando el usuario inicia sesión)
  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  // Cargar todas las tareas del usuario desde MySQL API
  Future<void> loadUserTasks(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUserId = userId;
      final taskList = await ApiService.getTasks(userId: userId);
      
      _tasks = taskList.map((taskData) {
        // Parse labels from JSON string if necessary
        List<String> labels = [];
        if (taskData['labels'] != null) {
          final labelsData = taskData['labels'];
          if (labelsData is String) {
            try {
              final parsed = jsonDecode(labelsData);
              labels = List<String>.from(parsed as List);
            } catch (e) {
              labels = [];
            }
          } else if (labelsData is List) {
            labels = List<String>.from(labelsData);
          }
        }
        
        return Task(
          id: taskData['id'] as String,
          title: taskData['title'] as String,
          description: taskData['description'] as String?,
          dueDate: taskData['due_date'] != null 
            ? DateTime.parse(taskData['due_date'] as String).toLocal()
            : DateTime.now(),
          status: _parseTaskStatus(taskData['status'] as String? ?? 'pending'),
          priority: _parseTaskPriority(taskData['priority'] as String? ?? 'medium'),
          projectId: taskData['project_id'] as String?,
          color: taskData['color'] as String? ?? '#6366F1',
          labels: labels,
          createdBy: userId,
          createdAt: DateTime.parse(taskData['created_at'] as String),
          updatedAt: DateTime.parse(taskData['updated_at'] as String),
        );
      }).toList();
      _applyFilters();
      debugPrint('✅ ${_tasks.length} tareas cargadas desde API');
    } catch (e) {
      debugPrint('❌ Error loading tasks from API: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener tareas por proyecto
  List<Task> getTasksByProject(String projectId) {
    return _tasks.where((task) => task.projectId == projectId).toList();
  }

  // Obtener tareas por estado
  List<Task> getTasksByStatus(TaskStatus status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  // Obtener tareas por fecha
  List<Task> getTasksByDate(DateTime date) {
    // Convertir fecha local a UTC para comparación consistente
    final dateUtc = date.toUtc();
    // Luego obtener medianoche UTC de ese día
    final normalizedDate = DateTime.utc(dateUtc.year, dateUtc.month, dateUtc.day);
    return _tasks.where((task) {
      final taskDateUtc = task.dueDate.toUtc();
      return taskDateUtc.year == normalizedDate.year &&
          taskDateUtc.month == normalizedDate.month &&
          taskDateUtc.day == normalizedDate.day;
    }).toList();
  }

  // Crear tarea en API (persistencia en BD)
  Future<void> createTask(Task task) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Guardar en MySQL a través de API
      // Convertir a UTC para garantizar consistencia entre zonas horarias
      final result = await ApiService.createTask({
        'user_id': _currentUserId!,
        'title': task.title,
        'description': task.description,
        'due_date': task.dueDate.toUtc().toIso8601String(),
        'status': task.status.toString().split('.').last,
        'priority': task.priority.toString().split('.').last,
        'project_id': task.projectId,
        'color': task.color,
        'labels': task.labels,
        'created_by': task.createdBy,
      });

      if (!result.containsKey('error')) {
        // Agregar a la lista local
        _tasks.add(task);
        _applyFilters();
        debugPrint('✅ Tarea creada en API: ${task.title}');
      } else {
        debugPrint('❌ Error en API: ${result['error']}');
        throw Exception(result['error']);
      }
    } catch (e) {
      debugPrint('❌ Error creating task: $e');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  // Agregar tarea rápidamente (con persistencia)
  Future<void> addTask({
    required String title,
    String? description,
    required DateTime dueDate,
    TaskPriority priority = TaskPriority.medium,
    String color = '#6366F1',
    List<String> labels = const [],
    String? projectId,
    int? estimatedHours,
    String? userId, // Parámetro opcional para pasar el userId explícitamente
  }) async {
    // Determinar el userId a usar
    String actualUserId;
    if (userId != null) {
      actualUserId = userId;
      _currentUserId = userId; // Actualizar si se proporciona explícitamente
    } else if (_currentUserId != null) {
      actualUserId = _currentUserId!;
    } else {
      throw Exception('Usuario no autenticado. Por favor inicia sesión.');
    }

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      color: color,
      labels: labels,
      projectId: projectId,
      createdBy: actualUserId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      estimatedHours: estimatedHours,
    );

    await createTask(task);
  }

  // Actualizar tarea en API
  Future<void> updateTask(Task updatedTask) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentUserId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Actualizar en MySQL a través de API
      final result = await ApiService.updateTask(
        taskId: updatedTask.id,
        updates: {
          'title': updatedTask.title,
          'description': updatedTask.description,
          'due_date': updatedTask.dueDate.toIso8601String().split('T')[0],
          'status': updatedTask.status.toString().split('.').last,
          'priority': updatedTask.priority.toString().split('.').last,
          'project_id': updatedTask.projectId,
          'color': updatedTask.color,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      if (!result.containsKey('error')) {
        final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
        if (index != -1) {
          _tasks[index] = updatedTask;
          _applyFilters();
        }
        debugPrint('✅ Tarea actualizada en API');
      }
    } catch (e) {
      debugPrint('❌ Error updating task: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Eliminar tarea desde API
  Future<void> deleteTask(String taskId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Eliminar de MySQL a través de API
      final success = await ApiService.deleteTask(taskId);

      if (success) {
        _tasks.removeWhere((t) => t.id == taskId);
        _applyFilters();
        debugPrint('✅ Tarea eliminada de API');
      }
    } catch (e) {
      debugPrint('❌ Error deleting task: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Marcar tarea como completada
  Future<void> completeTask(String taskId, {int? actualHours}) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final updatedTask = _tasks[taskIndex].copyWith(
        status: TaskStatus.completed,
        actualHours: actualHours,
        updatedAt: DateTime.now(),
      );
      await updateTask(updatedTask);
    }
  }

  // Cambiar estado de tarea
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final updatedTask = task.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      await updateTask(updatedTask);
    }
  }

  // Aplicar filtros
  void _applyFilters() {
    _filteredTasks = _tasks;
  }

  // Buscar tareas por título
  void searchTasks(String query) {
    if (query.isEmpty) {
      _filteredTasks = List.from(_tasks);
    } else {
      _filteredTasks = _tasks
          .where((task) => task.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  // Estadísticas de tareas
  Map<String, int> getTaskStats() {
    return {
      'total': _tasks.length,
      'completed': _tasks.where((t) => t.status == TaskStatus.completed).length,
      'inProgress': _tasks.where((t) => t.status == TaskStatus.inProgress).length,
      'pending': _tasks.where((t) => t.status == TaskStatus.pending).length,
      'overdue': _tasks.where((t) => t.isOverdue).length,
    };
  }

  // Parsear estado de tarea
  TaskStatus _parseTaskStatus(String status) {
    switch (status) {
      case 'completed':
        return TaskStatus.completed;
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'pending':
      default:
        return TaskStatus.pending;
    }
  }

  // Parsear prioridad de tarea
  TaskPriority _parseTaskPriority(String priority) {
    switch (priority) {
      case 'urgent':
        return TaskPriority.urgent;
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      case 'low':
      default:
        return TaskPriority.low;
    }
  }

  // Cargar tarea desde BD (usado por SyncService)
  Future<void> addTaskFromDb({
    required String id,
    required String userId,
    required String title,
    String? description,
    DateTime? dueDate,
    required String status,
    required String priority,
    String? projectId,
    String? color,
    dynamic labels,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final task = Task(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate ?? DateTime.now(),
      status: _parseTaskStatus(status),
      priority: _parseTaskPriority(priority),
      projectId: projectId,
      color: color ?? '#6366F1',
      labels: labels is String ? (labels.isEmpty ? [] : List<String>.from(labels.split(','))) : List<String>.from(labels ?? []),
      createdBy: createdBy ?? userId,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
    _tasks.add(task);
  }

  // Limpiar todas las tareas
  void clear() {
    _tasks.clear();
    _filteredTasks.clear();
  }
}
