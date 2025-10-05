import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:procastimate_app/mainapp/profile_screen.dart';
import 'package:procastimate_app/mainapp/settings_screen.dart';
import 'package:procastimate_app/mainapp/calendar_screen.dart';
import 'package:procastimate_app/mainapp/score_screen.dart';
import 'package:procastimate_app/models/task.dart';
import 'package:procastimate_app/models/task_data.dart';

class MainScreen extends StatefulWidget {
  final String? email;
  const MainScreen({super.key, this.email});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(
      tasksByDate.map((key, tasks) => MapEntry(
            key,
            tasks.map((t) => t.toJson()).toList(),
          )),
    );
    await prefs.setString('tasksByDate', jsonString);
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('tasksByDate');
    if (jsonString != null) {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      setState(() {
        tasksByDate.clear();
        decoded.forEach((key, list) {
          tasksByDate[key] =
              (list as List).map((t) => Task.fromJson(t)).toList();
        });
      });
    }
  }

  void _deleteTask(String dateKey, String taskId) {
    setState(() {
      final tasks = tasksByDate[dateKey];
      if (tasks == null) return;
      tasks.removeWhere((t) => t.id == taskId);
      if (tasks.isEmpty) {
        tasksByDate.remove(dateKey);
      }
    });
    saveTasks();
  }

  void _openCreateTaskDialogForDate(String dateKey) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime dueDate = DateTime.parse(dateKey);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text("Add Task"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      final task = Task(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleController.text,
                        description: descController.text,
                        dueDate: dueDate,
                      );
                      setState(() => addTask(task));
                      saveTasks();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openCreateTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? dueDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text("Create Task"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dueDate != null
                                ? "Due: ${DateFormat('MM/dd/yyyy HH:mm').format(dueDate!)}"
                                : "No due date",
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: dueDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(dueDate ?? DateTime.now()),
                              );
                              if (pickedTime != null) {
                                setDialogState(() {
                                  dueDate = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                });
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty && dueDate != null) {
                      final task = Task(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleController.text,
                        description: descController.text,
                        dueDate: dueDate,
                      );
                      setState(() => addTask(task));
                      saveTasks();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _toggleTaskCompletion(String dateKey, String taskId) {
    setState(() {
      final tasks = tasksByDate[dateKey];
      if (tasks == null) return;
      final index = tasks.indexWhere((t) => t.id == taskId);
      if (index == -1) return;

      final task = tasks[index];
      final updated = task.copyWith(
        completed: !task.completed,
        completedAt: !task.completed ? DateTime.now() : null,
      );

      tasks[index] = updated;
      tasks.sort((a, b) {
        if (a.completed == b.completed) return 0;
        return a.completed ? 1 : -1;
      });
    });
    saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.email != null ? widget.email!.split('@').first : 'Guest';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EF), // same beige as calendar
      body: SafeArea(
        child: Column(
          children: [
            //  TOP BAR (bigger and cleaner)
            Container(
              width: double.infinity,
              height: 72, // was 56 → now taller
              color: Colors.brown.shade800,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.person, color: Colors.white, size: 26),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      "Procastimate",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.settings, color: Colors.white, size: 26),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // WELCOME + LOGO
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 14),
              child: Column(
                children: [
                  SizedBox(
                    height: 100,
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome, $username',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            //  TASK AREA
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: tasksByDate.entries.map((entry) {
                    final dateKey = entry.key;
                    final tasks = entry.value;
                    final dateLabel = DateFormat("MMMM d, yyyy").format(DateTime.parse(dateKey));
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _DateColumn(
                        dateLabel: dateLabel,
                        dateKey: dateKey,
                        tasks: tasks,
                        onToggleTask: (taskId) => _toggleTaskCompletion(dateKey, taskId),
                        onDeleteTask: (taskId) => _deleteTask(dateKey, taskId),
                        onAddTask: (key) => _openCreateTaskDialogForDate(key),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            //  CREATE TASK BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _openCreateTaskDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: const Text(
                    'CREATE TASK',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      //  BOTTOM NAV
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          setState(() => _selectedIndex = i);
          if (i == 0) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CalendarScreen()));
          } else if (i == 2) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScoreScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Score'),
        ],
        selectedItemColor: Colors.brown.shade800,
        unselectedItemColor: Colors.grey.shade600,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}

class _DateColumn extends StatelessWidget {
  final String dateLabel;
  final String dateKey;
  final List<Task> tasks;
  final Function(String) onToggleTask;
  final Function(String) onDeleteTask;
  final Function(String) onAddTask;

  const _DateColumn({
    required this.dateLabel,
    required this.dateKey,
    required this.tasks,
    required this.onToggleTask,
    required this.onDeleteTask,
    required this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            ...tasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TaskCard(
                    task: task,
                    onToggle: () => onToggleTask(task.id),
                    onDelete: () => onDeleteTask(task.id),
                  ),
                )),
            InkWell(
              onTap: () => onAddTask(dateKey),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: const [
                    Icon(Icons.add, color: Colors.green, size: 18),
                    SizedBox(width: 6),
                    Text("Add Task", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: task.completed ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    decoration: task.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (task.dueDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      "Due: ${DateFormat('MM/dd HH:mm').format(task.dueDate!)}",
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ),
                if (task.description != null && task.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(task.description!, style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              task.completed ? Icons.check_circle : Icons.check_circle_outline,
              color: task.completed ? Colors.green : Colors.grey,
            ),
            onPressed: onToggle,
          ),
          if (task.completed)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
