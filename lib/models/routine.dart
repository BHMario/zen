enum Frequency { daily, weekly, biWeekly, monthly }
enum DayOfWeek { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

class Routine {
  final String id;
  final String name;
  final String? description;
  final Frequency frequency;
  final List<DayOfWeek> daysOfWeek; // Para rutinas semanales
  final String color;
  final String createdBy;
  final List<String> sharedWith; // IDs de usuarios
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? scheduleTime; // Formato: "HH:mm" para rutinas con horario
  final int? durationMinutes;
  final List<String> labels;
  final int repeatEveryDays; // Repetir cada N días (1 = diario, 7 = semanal, etc.)
  final List<String> steps; // Pasos sugeridos para completar la rutina
  final int currentStreak;
  final int maxStreak;
  final DateTime? lastCompletedDate;
  final String? attachmentUrl;
  final String? attachmentType;

  Routine({
    required this.id,
    required this.name,
    this.description,
    this.frequency = Frequency.daily,
    this.daysOfWeek = const [],
    this.color = '#2a2a2a',
    required this.createdBy,
    this.sharedWith = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.scheduleTime,
    this.durationMinutes,
    this.labels = const [],
    this.repeatEveryDays = 1,
    this.steps = const [],
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.lastCompletedDate,
    this.attachmentUrl,
    this.attachmentType,
  });

  Routine copyWith({
    String? id,
    String? name,
    String? description,
    Frequency? frequency,
    List<DayOfWeek>? daysOfWeek,
    String? color,
    String? createdBy,
    List<String>? sharedWith,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? scheduleTime,
    int? durationMinutes,
    List<String>? labels,
    int? repeatEveryDays,
    List<String>? steps,
    int? currentStreak,
    int? maxStreak,
    DateTime? lastCompletedDate,
    String? attachmentUrl,
    String? attachmentType,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      color: color ?? this.color,
      createdBy: createdBy ?? this.createdBy,
      sharedWith: sharedWith ?? this.sharedWith,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      labels: labels ?? this.labels,
      repeatEveryDays: repeatEveryDays ?? this.repeatEveryDays,
      steps: steps ?? this.steps,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentType: attachmentType ?? this.attachmentType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'frequency': frequency.name,
      'daysOfWeek': daysOfWeek.map((e) => e.name).toList(),
      'color': color,
      'createdBy': createdBy,
      'sharedWith': sharedWith,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'scheduleTime': scheduleTime,
      'durationMinutes': durationMinutes,
      'labels': labels,
      'repeatEveryDays': repeatEveryDays,
      'steps': steps,
      'currentStreak': currentStreak,
      'maxStreak': maxStreak,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
    };
  }

  factory Routine.fromMap(Map<String, dynamic> map) {
    return Routine(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      frequency: Frequency.values.byName(map['frequency'] as String? ?? 'daily'),
      daysOfWeek: (map['daysOfWeek'] as List<dynamic>? ?? [])
          .map((e) => DayOfWeek.values.byName(e as String))
          .toList(),
      color: map['color'] as String? ?? '#8b5cf6',
      createdBy: map['createdBy'] as String,
      sharedWith: List<String>.from(map['sharedWith'] as List<dynamic>? ?? []),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isActive: map['isActive'] as bool? ?? true,
      scheduleTime: map['scheduleTime'] as String?,
      durationMinutes: map['durationMinutes'] as int?,
      labels: List<String>.from(map['labels'] as List<dynamic>? ?? []),
      repeatEveryDays: map['repeatEveryDays'] as int? ?? 1,
      steps: List<String>.from(map['steps'] as List<dynamic>? ?? []),
      currentStreak: map['currentStreak'] as int? ?? 0,
      maxStreak: map['maxStreak'] as int? ?? 0,
      lastCompletedDate: map['lastCompletedDate'] != null
          ? DateTime.parse(map['lastCompletedDate'] as String)
          : null,
      attachmentUrl: map['attachmentUrl'] as String?,
      attachmentType: map['attachmentType'] as String?,
    );
  }
}
