// task_data.dart
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'task.dart';

/// In-memory map of tasks grouped by date (yyyy-MM-dd)
final Map<String, List<Task>> tasksByDate = {};

/// Add a new task and persist locally
void addTask(Task task) {
  final key = DateFormat('yyyy-MM-dd').format(task.dueDate ?? DateTime.now());
  if (!tasksByDate.containsKey(key)) {
    tasksByDate[key] = [];
  }
  tasksByDate[key]!.add(task);
  saveTasksToPrefs();
}

/// Save all tasks to SharedPreferences (local persistence)
Future<void> saveTasksToPrefs() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final serialized = tasksByDate.map(
      (key, tasks) => MapEntry(key, tasks.map((t) => t.toJson()).toList()),
    );
    await prefs.setString('tasks', jsonEncode(serialized));
  } catch (e) {
    print('Error saving tasks locally: $e');
  }
}

/// Load all tasks from SharedPreferences into memory
Future<void> loadTasksFromPrefs() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('tasks');
    if (jsonString == null) return;

    final Map<String, dynamic> decoded = jsonDecode(jsonString);
    tasksByDate.clear();

    decoded.forEach((key, value) {
      final taskList =
          (value as List).map((json) => Task.fromJson(json)).toList();
      tasksByDate[key] = taskList;
    });
  } catch (e) {
    print('Error loading tasks locally: $e');
  }
}

/// Update a specific task’s completion state and save
void updateTaskCompletion(String taskId, bool completed) {
  for (final entry in tasksByDate.entries) {
    final updatedList = entry.value.map((task) {
      if (task.id == taskId) {
        return task.copyWith(
          completed: completed,
          completedAt: completed ? DateTime.now() : null,
        );
      }
      return task;
    }).toList();
    tasksByDate[entry.key] = updatedList;
  }
  saveTasksToPrefs();
}
