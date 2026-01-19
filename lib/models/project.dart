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

  Project({
    required this.id,
    required this.name,
    this.description,
    this.color = '#3b82f6',
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
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      color: map['color'] as String? ?? '#3b82f6',
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
    );
  }

  int get completedTasksCount => 0; // Se calculará con el contexto de tareas
  int get totalTasksCount => taskIds.length;
  double get completionPercentage => totalTasksCount == 0 ? 0 : (completedTasksCount / totalTasksCount) * 100;
}
