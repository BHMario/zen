enum TaskStatus { pending, inProgress, completed, cancelled }
enum TaskPriority { low, medium, high, urgent }

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final TaskStatus status;
  final TaskPriority priority;
  final String? projectId;
  final List<String> labels;
  final String color;
  final String createdBy;
  final List<String> assignedTo; // IDs de usuarios
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> attachmentUrls;
  final int? estimatedHours;
  final int? actualHours;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.medium,
    this.projectId,
    this.labels = const [],
    this.color = '#6366f1',
    required this.createdBy,
    this.assignedTo = const [],
    required this.createdAt,
    required this.updatedAt,
    this.attachmentUrls = const [],
    this.estimatedHours,
    this.actualHours,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    TaskPriority? priority,
    String? projectId,
    List<String>? labels,
    String? color,
    String? createdBy,
    List<String>? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? attachmentUrls,
    int? estimatedHours,
    int? actualHours,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      projectId: projectId ?? this.projectId,
      labels: labels ?? this.labels,
      color: color ?? this.color,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      actualHours: actualHours ?? this.actualHours,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'priority': priority.name,
      'projectId': projectId,
      'labels': labels,
      'color': color,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'attachmentUrls': attachmentUrls,
      'estimatedHours': estimatedHours,
      'actualHours': actualHours,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: DateTime.parse(map['dueDate'] as String),
      status: TaskStatus.values.byName(map['status'] as String? ?? 'pending'),
      priority: TaskPriority.values.byName(map['priority'] as String? ?? 'medium'),
      projectId: map['projectId'] as String?,
      labels: List<String>.from(map['labels'] as List<dynamic>? ?? []),
      color: map['color'] as String? ?? '#6366f1',
      createdBy: map['createdBy'] as String,
      assignedTo: List<String>.from(map['assignedTo'] as List<dynamic>? ?? []),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      attachmentUrls: List<String>.from(map['attachmentUrls'] as List<dynamic>? ?? []),
      estimatedHours: map['estimatedHours'] as int?,
      actualHours: map['actualHours'] as int?,
    );
  }

  bool get isOverdue => dueDate.toUtc().isBefore(DateTime.now().toUtc()) && status != TaskStatus.completed;
  bool get isCompleted => status == TaskStatus.completed;
  bool get isInProgress => status == TaskStatus.inProgress;
}
