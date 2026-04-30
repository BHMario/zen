import 'package:flutter/foundation.dart';
import 'package:zen/models/models.dart';
import 'package:zen/services/services.dart';

class ProjectProvider extends ChangeNotifier {
  List<Project> _projects = [];
  bool _isLoading = false;
  String? _currentUserId;

  // Getters
  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;

  // Establecer usuario actual
  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  // Cargar todos los proyectos del usuario desde API
  Future<void> loadUserProjects(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUserId = userId;
      final projectList = await ApiService.getProjects(userId: userId);
      
      _projects = projectList.map((projectData) {
        // Convertir fechas YYYY-MM-DD a DateTime a las 00:00:00 local
        DateTime? parseDate(String? dateStr) {
          if (dateStr == null) return null;
          try {
            final parts = dateStr.split('T')[0].split('-');
            return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          } catch (e) {
            return null;
          }
        }

        return Project(
          id: projectData['id'] as String,
          name: projectData['name'] as String,
          description: projectData['description'] as String?,
          color: projectData['color'] as String? ?? '#3B82F6',
          status: _parseProjectStatus(projectData['status'] as String? ?? 'active'),
          startDate: parseDate(projectData['start_date'] as String?) ?? DateTime.now(),
          endDate: parseDate(projectData['end_date'] as String?),
          createdBy: userId,
          createdAt: DateTime.parse(projectData['created_at'] as String),
          updatedAt: DateTime.parse(projectData['updated_at'] as String),
        );
      }).toList();
      debugPrint('✅ ${_projects.length} proyectos cargados desde API');
    } catch (e) {
      debugPrint('❌ Error loading projects from API: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Crear proyecto en API
  Future<void> createProject(Project project) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Guardar en MySQL a través de API
      // Enviar SOLO la fecha en formato YYYY-MM-DD, sin horas
      final result = await ApiService.createProject(
        userId: _currentUserId!,
        name: project.name,
        description: project.description,
        color: project.color,
        startDate: project.startDate.toString().split(' ')[0],
        endDate: project.endDate != null ? project.endDate!.toString().split(' ')[0] : null,
        status: project.status.toString().split('.').last,
        createdBy: project.createdBy,
      );

      if (!result.containsKey('error')) {
        _projects.add(project);
        debugPrint('✅ Proyecto creado en API: ${project.name}');
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      debugPrint('❌ Error creating project: $e');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  // Agregar proyecto rápidamente
  Future<void> addProject({
    required String name,
    String? description,
    String color = '#3B82F6',
    required DateTime startDate,
    DateTime? endDate,
    String? userId,
  }) async {
    // Determinar el userId a usar
    String actualUserId;
    if (userId != null) {
      actualUserId = userId;
      _currentUserId = userId;
    } else if (_currentUserId != null) {
      actualUserId = _currentUserId!;
    } else {
      throw Exception('Usuario no autenticado. Por favor inicia sesión.');
    }

    // Normalizar fechas: establecer hora a 00:00:00 para evitar problemas de zona horaria
    final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEndDate = endDate != null 
      ? DateTime(endDate.year, endDate.month, endDate.day)
      : null;

    final project = Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      color: color,
      startDate: normalizedStartDate,
      endDate: normalizedEndDate,
      createdBy: actualUserId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await createProject(project);
  }

  // Actualizar proyecto en API
  Future<void> updateProject(Project project) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentUserId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Actualizar en MySQL a través de API
      // Enviar SOLO la fecha en formato YYYY-MM-DD, sin horas
      final result = await ApiService.updateProject(
        projectId: project.id,
        updates: {
          'name': project.name,
          'description': project.description,
          'color': project.color,
          'status': project.status.toString().split('.').last,
          'start_date': project.startDate.toString().split(' ')[0],
          'end_date': project.endDate != null ? project.endDate!.toString().split(' ')[0] : null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
      );

      if (!result.containsKey('error')) {
        final index = _projects.indexWhere((p) => p.id == project.id);
        if (index != -1) {
          _projects[index] = project;
        }
        debugPrint('✅ Proyecto actualizado en API');
      }
    } catch (e) {
      debugPrint('❌ Error updating project: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Eliminar proyecto desde API
  Future<void> deleteProject(String projectId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Eliminar de MySQL a través de API
      final success = await ApiService.deleteProject(projectId);

      if (success) {
        _projects.removeWhere((p) => p.id == projectId);
        debugPrint('✅ Proyecto eliminado de API');
      }
    } catch (e) {
      debugPrint('❌ Error deleting project: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener proyecto por ID
  Project? getProjectById(String projectId) {
    try {
      return _projects.firstWhere((p) => p.id == projectId);
    } catch (e) {
      return null;
    }
  }

  // Obtener proyectos activos
  List<Project> getActiveProjects() {
    return _projects.where((p) => p.status == ProjectStatus.active).toList();
  }

  // Obtener proyectos completados
  List<Project> getCompletedProjects() {
    return _projects.where((p) => p.status == ProjectStatus.completed).toList();
  }

  // Obtener proyectos por fecha (para calendario)
  List<Project> getProjectsByDate(DateTime date) {
    // Convertir fecha local a UTC para comparación consistente (igual que tareas)
    final dateUtc = date.toUtc();
    // Obtener medianoche UTC de ese día
    final normalizedDate = DateTime.utc(dateUtc.year, dateUtc.month, dateUtc.day);
    
    return _projects
        .where((project) {
          final startDateUtc = project.startDate.toUtc();
          final startMatches = startDateUtc.year == normalizedDate.year &&
              startDateUtc.month == normalizedDate.month &&
              startDateUtc.day == normalizedDate.day;
          
          final endDateUtc = project.endDate?.toUtc();
          final endMatches = endDateUtc != null &&
              endDateUtc.year == normalizedDate.year &&
              endDateUtc.month == normalizedDate.month &&
              endDateUtc.day == normalizedDate.day;
          
          // Mostrar el proyecto si coincide con fecha de inicio O fecha de fin
          return startMatches || endMatches;
        })
        .toList();
  }

  // Parsear estado de proyecto
  ProjectStatus _parseProjectStatus(String status) {
    switch (status.toLowerCase()) {
      case 'planning':
        return ProjectStatus.planning;
      case 'active':
        return ProjectStatus.active;
      case 'onhold':
      case 'on_hold':
        return ProjectStatus.onHold;
      case 'completed':
        return ProjectStatus.completed;
      default:
        return ProjectStatus.active;
    }
  }

  // Cargar proyecto desde BD (usado por SyncService)
  Future<void> addProjectFromDb({
    required String id,
    required String userId,
    required String name,
    String? description,
    String? color,
    DateTime? startDate,
    DateTime? endDate,
    required String status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final project = Project(
      id: id,
      name: name,
      description: description,
      color: color ?? '#3B82F6',
      status: _parseProjectStatus(status),
      startDate: startDate ?? DateTime.now(),
      endDate: endDate,
      createdBy: createdBy ?? userId,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
    _projects.add(project);
  }

  // Limpiar todos los proyectos
  void clear() {
    _projects.clear();
  }
}
