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
        // Convertir fechas YYYY-MM-DD a DateTime a las 00:00:00 local (sin conversión de zona horaria)
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
            debugPrint('❌ Error parsing project date: $e');
            return null;
          }
        }

        return Project(
          id: projectData['id'] as String,
          name: projectData['name'] as String,
          description: projectData['description'] as String?,
          color: projectData['color'] as String? ?? '#2A2A2A',
          status: _parseProjectStatus(projectData['status'] as String? ?? 'active'),
          startDate: parseDate(projectData['start_date'] as String?) ?? DateTime.now(),
          endDate: parseDate(projectData['end_date'] as String?),
          createdBy: userId,
          createdAt: DateTime.parse(projectData['created_at'] as String),
          updatedAt: DateTime.parse(projectData['updated_at'] as String),
          attachmentUrl: projectData['attachment_url'] as String?,
          attachmentType: projectData['attachment_type'] as String?,
            completedAt: projectData['completed_at'] != null
              ? DateTime.parse(projectData['completed_at'] as String)
              : null,
            completionAttachmentUrl:
              projectData['completion_attachment_url'] as String?,
            completionAttachmentType:
              projectData['completion_attachment_type'] as String?,
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
      // Convertir fechas al formato YYYY-MM-DD (sin tiempo) de forma SEGURA
      final startDateString = '${project.startDate.year.toString().padLeft(4, '0')}-${project.startDate.month.toString().padLeft(2, '0')}-${project.startDate.day.toString().padLeft(2, '0')}';
      final endDateString = project.endDate != null
          ? '${project.endDate!.year.toString().padLeft(4, '0')}-${project.endDate!.month.toString().padLeft(2, '0')}-${project.endDate!.day.toString().padLeft(2, '0')}'
          : null;

      final result = await ApiService.createProject(
        userId: _currentUserId!,
        name: project.name,
        description: project.description,
        color: project.color,
        startDate: startDateString,
        endDate: endDateString,
        status: project.status.toString().split('.').last,
        createdBy: project.createdBy,
        attachmentUrl: project.attachmentUrl,
        attachmentType: project.attachmentType,
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
    String color = '#2A2A2A',
    required DateTime startDate,
    DateTime? endDate,
    String? attachmentUrl,
    String? attachmentType,
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
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
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

      // Convertir fechas al formato YYYY-MM-DD (sin tiempo)
      final startDateString = '${project.startDate.year.toString().padLeft(4, '0')}-${project.startDate.month.toString().padLeft(2, '0')}-${project.startDate.day.toString().padLeft(2, '0')}';
      final endDateString = project.endDate != null
          ? '${project.endDate!.year.toString().padLeft(4, '0')}-${project.endDate!.month.toString().padLeft(2, '0')}-${project.endDate!.day.toString().padLeft(2, '0')}'
          : null;

      // Actualizar en MySQL a través de API
      final result = await ApiService.updateProject(
        projectId: project.id,
        updates: {
          'name': project.name,
          'description': project.description,
          'color': project.color,
          'status': project.status.toString().split('.').last,
          'start_date': startDateString,
          'end_date': endDateString,
          'attachment_url': project.attachmentUrl,
          'attachment_type': project.attachmentType,
          'completed_at': project.completedAt?.toIso8601String(),
          'completion_attachment_url': project.completionAttachmentUrl,
          'completion_attachment_type': project.completionAttachmentType,
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

  List<Project> getProjectsByDate(DateTime date) {
    // Normalizar la fecha a medianoche local para comparación
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    return _projects
        .where((project) {
          // Normalizar fechas del proyecto
          final projectStart = DateTime(project.startDate.year, project.startDate.month, project.startDate.day);
          final projectEnd = project.endDate != null
              ? DateTime(project.endDate!.year, project.endDate!.month, project.endDate!.day)
              : null;
          
          // Mostrar proyecto SOLO en la fecha de inicio o en la fecha de fin
          final isStart = normalizedDate.isAtSameMomentAs(projectStart);
          final isEnd = projectEnd != null && normalizedDate.isAtSameMomentAs(projectEnd);
          
          return isStart || isEnd;
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
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    final project = Project(
      id: id,
      name: name,
      description: description,
      color: color ?? '#2A2A2A',
      status: _parseProjectStatus(status),
      startDate: startDate ?? DateTime.now(),
      endDate: endDate,
      createdBy: createdBy ?? userId,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
    );
    _projects.add(project);
  }

  // Limpiar todos los proyectos
  void clear() {
    _projects.clear();
  }
}
