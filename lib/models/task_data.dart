import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'task.dart';

final Map<String, List<Task>> tasksByDate = {};

void addTask(Task task) {
  final key = DateFormat('yyyy-MM-dd').format(task.dueDate ?? DateTime.now());
  if (!tasksByDate.containsKey(key)) {
    tasksByDate[key] = [];
  }
  tasksByDate[key]!.add(task);
  saveTasksToPrefs(); // Save after adding
}

/// Save all tasks to local storage
Future<void> saveTasksToPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final serialized = tasksByDate.map((key, tasks) =>
      MapEntry(key, tasks.map((t) => t.toJson()).toList()));
  await prefs.setString('tasks', jsonEncode(serialized));
}

/// Load all tasks from local storage
Future<void> loadTasksFromPrefs() async {
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
}

/// Update a specific task (e.g., when marking complete)
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
  saveTasksToPrefs(); // persist after change
}
