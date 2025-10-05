import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskService {
  TaskService._internal();
  static final TaskService instance = TaskService._internal();

  static const String _kTasksKey = 'tasks_v1';
  final ValueNotifier<List<Task>> tasks = ValueNotifier<List<Task>>([]);
  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> streak = ValueNotifier<int>(0);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTasksKey);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      tasks.value = list.map((m) => Task.fromJson(m)).toList();
    } else {
      tasks.value = [];
    }
    _recomputeScoreAndStreak();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(tasks.value.map((t) => t.toJson()).toList());
    await prefs.setString(_kTasksKey, encoded);
    _recomputeScoreAndStreak();
  }

  Future<void> addTask({required String title, String? description, DateTime? dueDate, int points = 10}) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final t = Task(id: id, title: title, description: description, dueDate: dueDate, points: points);
    tasks.value = [t, ...tasks.value];
    await _save();
  }

  Future<void> completeTask(String id) async {
    final list = tasks.value.map((t) {
      if (t.id == id && !t.completed) {
        return t.copyWith(completed: true, completedAt: DateTime.now());
      }
      return t;
    }).toList();
    tasks.value = list;
    await _save();
  }

  Future<void> deleteTask(String id) async {
    tasks.value = tasks.value.where((t) => t.id != id).toList();
    await _save();
  }

  void _recomputeScoreAndStreak() {
    final completed = tasks.value.where((t) => t.completed).toList();
    final total = completed.fold<int>(0, (s, t) => s + t.points);
    score.value = total;

    final days = completed
        .where((t) => t.completedAt != null)
        .map((t) => DateTime.utc(t.completedAt!.year, t.completedAt!.month, t.completedAt!.day))
        .toSet();

    int streakCount = 0;
    var cur = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    while (days.contains(cur)) {
      streakCount++;
      cur = cur.subtract(const Duration(days: 1));
    }
    streak.value = streakCount;
  }
}

