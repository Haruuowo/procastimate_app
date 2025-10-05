class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final int points;
  final bool completed;

  Task({
    required this.id,
    required this.title,
    this.description,
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
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'points': points,
        'completed': completed,
      };

  factory Task.fromJson(Map<String, dynamic> m) => Task(
        id: m['id'] as String,
        title: m['title'] as String,
        description: m['description'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
        dueDate: m['dueDate'] != null ? DateTime.parse(m['dueDate'] as String) : null,
        completedAt: m['completedAt'] != null ? DateTime.parse(m['completedAt'] as String) : null,
        points: (m['points'] as int?) ?? 10,
        completed: (m['completed'] as bool?) ?? false,
      );
}