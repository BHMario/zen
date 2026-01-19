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
        return Project(
          id: projectData['id'] as String,
          name: projectData['name'] as String,
          description: projectData['description'] as String?,
          color: projectData['color'] as String? ?? '#3B82F6',
          status: _parseProjectStatus(projectData['status'] as String? ?? 'active'),
          startDate: projectData['start_date'] != null
              ? DateTime.parse(projectData['start_date'] as String).toLocal()
              : DateTime.now(),
          endDate: projectData['end_date'] != null 
              ? DateTime.parse(projectData['end_date'] as String).toLocal()
              : null,
          createdBy: userId,
          createdAt: DateTime.parse(projectData['created_at'] as String).toLocal(),
          updatedAt: DateTime.parse(projectData['updated_at'] as String).toLocal(),
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
      // Convertir a UTC para garantizar consistencia entre zonas horarias
      final result = await ApiService.createProject(
        userId: _currentUserId!,
        name: project.name,
        description: project.description,
        color: project.color,
        startDate: project.startDate.toUtc().toIso8601String(),
        endDate: project.endDate?.toUtc().toIso8601String(),
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

    final project = Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      color: color,
      startDate: startDate,
      endDate: endDate,
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
      // Convertir a UTC para garantizar consistencia entre zonas horarias
      final result = await ApiService.updateProject(
        projectId: project.id,
        updates: {
          'name': project.name,
          'description': project.description,
          'color': project.color,
          'status': project.status.toString().split('.').last,
          'start_date': project.startDate.toUtc().toIso8601String(),
          'end_date': project.endDate?.toUtc().toIso8601String(),
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
