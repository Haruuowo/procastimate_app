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
    this.subject, // ✅ Added to constructor
    DateTime? createdAt,
    this.dueDate,
    this.completedAt,
    this.points = 10,
    this.completed = false,
  }) : createdAt = createdAt ?? DateTime.now();

  //
  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? subject, // ✅ Added to copyWith
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
      subject: subject ?? this.subject, // ✅ Added
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
    'subject': subject, // ✅ Added
    'createdAt': createdAt.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'points': points,
    'completed': completed,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    subject: json['subject'], // ✅ Added
    createdAt: DateTime.parse(json['createdAt']),
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'])
        : null,
    points: json['points'] ?? 10,
    completed: json['completed'] ?? false,
  );
}
