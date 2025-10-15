class Task {
  final String id;
  final String title;
  final String? description;
  final String? subject;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final int points;
  final bool completed;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.subject,
    DateTime? createdAt,
    this.dueDate,
    this.completedAt,
    this.points = 10,
    this.completed = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? subject,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? completedAt,
    int? points,
    bool? completed,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      points: points ?? this.points,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'subject': subject,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'points': points,
        'completed': completed,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    // 🟢 Handles both Timestamp (Firestore) and String (local) dates safely
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      if (value is Map && value.containsKey('_seconds')) {
        // Firestore Timestamp when deserialized as Map
        return DateTime.fromMillisecondsSinceEpoch(value['_seconds'] * 1000);
      }
      return null;
    }

    return Task(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      subject: json['subject'],
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      dueDate: parseDate(json['dueDate']),
      completedAt: parseDate(json['completedAt']),
      points: json['points'] ?? 10,
      completed: json['completed'] ?? false,
    );
  }
}
