enum GoalCategory { health, career, personal, finance, education, relationships, other }
enum GoalTimeframe { shortTerm, mediumTerm, longTerm }

class Goal {
  final String id;
  final String title;
  final String? description;
  final GoalCategory category;
  final GoalTimeframe timeframe;
  final DateTime startDate;
  final DateTime targetDate;
  final double targetValue;
  final double currentValue;
  final String unit; // ej: "km", "horas", "libros"
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted;
  final String color;
  final List<String> milestones; // IDs o descripciones de hitos
  final List<String> labels;

  Goal({
    required this.id,
    required this.title,
    this.description,
    this.category = GoalCategory.other,
    this.timeframe = GoalTimeframe.mediumTerm,
    required this.startDate,
    required this.targetDate,
    this.targetValue = 1.0,
    this.currentValue = 0.0,
    this.unit = 'unidades',
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
    this.color = '#ec4899',
    this.milestones = const [],
    this.labels = const [],
  });

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    GoalCategory? category,
    GoalTimeframe? timeframe,
    DateTime? startDate,
    DateTime? targetDate,
    double? targetValue,
    double? currentValue,
    String? unit,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
    String? color,
    List<String>? milestones,
    List<String>? labels,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      timeframe: timeframe ?? this.timeframe,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      color: color ?? this.color,
      milestones: milestones ?? this.milestones,
      labels: labels ?? this.labels,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'timeframe': timeframe.name,
      'startDate': startDate.toIso8601String(),
      'targetDate': targetDate.toIso8601String(),
      'targetValue': targetValue,
      'currentValue': currentValue,
      'unit': unit,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isCompleted': isCompleted,
      'color': color,
      'milestones': milestones,
      'labels': labels,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      category: GoalCategory.values.byName(map['category'] as String? ?? 'other'),
      timeframe: GoalTimeframe.values.byName(map['timeframe'] as String? ?? 'mediumTerm'),
      startDate: DateTime.parse(map['startDate'] as String),
      targetDate: DateTime.parse(map['targetDate'] as String),
      targetValue: (map['targetValue'] as num?)?.toDouble() ?? 1.0,
      currentValue: (map['currentValue'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? 'unidades',
      createdBy: map['createdBy'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isCompleted: map['isCompleted'] as bool? ?? false,
      color: map['color'] as String? ?? '#ec4899',
      milestones: List<String>.from(map['milestones'] as List<dynamic>? ?? []),
      labels: List<String>.from(map['labels'] as List<dynamic>? ?? []),
    );
  }

  double get progress => targetValue == 0 ? 0 : (currentValue / targetValue).clamp(0.0, 1.0);
  bool get isOnTrack {
    final daysRemaining = targetDate.difference(DateTime.now()).inDays;
    final totalDays = targetDate.difference(startDate).inDays;
    if (totalDays == 0) return true;
    final expectedProgress = (totalDays - daysRemaining) / totalDays;
    return progress >= expectedProgress;
  }
}
