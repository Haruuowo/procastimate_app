import 'package:intl/intl.dart';
import 'task.dart';

final Map<String, List<Task>> tasksByDate = {};

void addTask(Task task) {
  final key = DateFormat('yyyy-MM-dd').format(task.dueDate ?? DateTime.now());
  if (!tasksByDate.containsKey(key)) {
    tasksByDate[key] = [];
  }
  tasksByDate[key]!.add(task);
}
