import 'task.dart';

enum ProjectStatus { planning, active, onHold, completed }

class Project {
  final String id;
  final String name;
  final String? description;
  final String color;
  final ProjectStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final String createdBy;
  final List<String> collaborators; // IDs de usuarios
  final List<String> taskIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? iconEmoji;
  final bool isPrivate;
  final String? attachmentUrl;
  final String? attachmentType;
  final DateTime? completedAt;
  final String? completionAttachmentUrl;
  final String? completionAttachmentType;

  Project({
    required this.id,
    required this.name,
    this.description,
    this.color = '#2a2a2a',
    this.status = ProjectStatus.planning,
    required this.startDate,
    this.endDate,
    required this.createdBy,
    this.collaborators = const [],
    this.taskIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.iconEmoji,
    this.isPrivate = false,
    this.attachmentUrl,
    this.attachmentType,
    this.completedAt,
    this.completionAttachmentUrl,
    this.completionAttachmentType,
  });

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    ProjectStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    String? createdBy,
    List<String>? collaborators,
    List<String>? taskIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? iconEmoji,
    bool? isPrivate,
    String? attachmentUrl,
    String? attachmentType,
    DateTime? completedAt,
    String? completionAttachmentUrl,
    String? completionAttachmentType,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdBy: createdBy ?? this.createdBy,
      collaborators: collaborators ?? this.collaborators,
      taskIds: taskIds ?? this.taskIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      isPrivate: isPrivate ?? this.isPrivate,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentType: attachmentType ?? this.attachmentType,
      completedAt: completedAt ?? this.completedAt,
      completionAttachmentUrl:
          completionAttachmentUrl ?? this.completionAttachmentUrl,
      completionAttachmentType:
          completionAttachmentType ?? this.completionAttachmentType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'status': status.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdBy': createdBy,
      'collaborators': collaborators,
      'taskIds': taskIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'iconEmoji': iconEmoji,
      'isPrivate': isPrivate,
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
      'completedAt': completedAt?.toIso8601String(),
      'completionAttachmentUrl': completionAttachmentUrl,
      'completionAttachmentType': completionAttachmentType,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      color: map['color'] as String? ?? '#2a2a2a',
      status: ProjectStatus.values.byName(map['status'] as String? ?? 'active'),
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate'] as String) : null,
      createdBy: map['createdBy'] as String,
      collaborators: List<String>.from(map['collaborators'] as List<dynamic>? ?? []),
      taskIds: List<String>.from(map['taskIds'] as List<dynamic>? ?? []),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      iconEmoji: map['iconEmoji'] as String?,
      isPrivate: map['isPrivate'] as bool? ?? false,
      attachmentUrl: map['attachmentUrl'] as String?,
      attachmentType: map['attachmentType'] as String?,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      completionAttachmentUrl: map['completionAttachmentUrl'] as String?,
      completionAttachmentType: map['completionAttachmentType'] as String?,
    );
  }

  // Obtener etiqueta de fecha para mostrar en calendario
  String getDateLabel(DateTime date) {
    // Normalizar la fecha a medianoche local para comparación
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final startNormalized = DateTime(startDate.year, startDate.month, startDate.day);
    
    final isStart = startNormalized == normalizedDate;
    
    if (endDate != null) {
      final endNormalized = DateTime(endDate!.year, endDate!.month, endDate!.day);
      final isEnd = endNormalized == normalizedDate;
      
      if (isStart && isEnd) {
        return '▶ $name (Inicio y Fin)';
      } else if (isStart) {
        return '▶ $name (Inicio)';
      } else if (isEnd) {
        return '■ $name (Fin)';
      }
    } else if (isStart) {
      return '▶ $name';
    }
    
    return name;
  }

  // Estos getters ahora aceptan la lista de tareas para calcular dinámicamente
  int getCompletedTasksCount(List<Task> allTasks) {
    // Filtrar tareas que pertenecen a este proyecto y están completadas
    return allTasks.where((t) => t.projectId == id && t.status == TaskStatus.completed).length;
  }

  int getTotalTasksCount(List<Task> allTasks) {
    return allTasks.where((t) => t.projectId == id).length;
  }

  double calculateCompletionPercentage(List<Task> allTasks) {
    final total = getTotalTasksCount(allTasks);
    if (total == 0) return 0;
    final completedCount = getCompletedTasksCount(allTasks);
    return (completedCount / total) * 100;
  }
}
