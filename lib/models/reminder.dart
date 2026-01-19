enum ReminderType { task, project, routine, goal }
enum ReminderFrequency { once, daily, weekly, custom }

class Reminder {
  final String id;
  final String itemId;
  final ReminderType type;
  final DateTime dateTime;
  final ReminderFrequency frequency;
  final String? message;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reminder({
    required this.id,
    required this.itemId,
    required this.type,
    required this.dateTime,
    this.frequency = ReminderFrequency.once,
    this.message,
    this.isActive = true,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Reminder copyWith({
    String? id,
    String? itemId,
    ReminderType? type,
    DateTime? dateTime,
    ReminderFrequency? frequency,
    String? message,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      frequency: frequency ?? this.frequency,
      message: message ?? this.message,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'type': type.name,
      'dateTime': dateTime.toIso8601String(),
      'frequency': frequency.name,
      'message': message,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as String,
      itemId: map['itemId'] as String,
      type: ReminderType.values.byName(map['type'] as String),
      dateTime: DateTime.parse(map['dateTime'] as String),
      frequency: ReminderFrequency.values.byName(map['frequency'] as String? ?? 'once'),
      message: map['message'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdBy: map['createdBy'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
