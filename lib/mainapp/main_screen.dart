// main_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Added for FirebaseAuth reference
import 'package:procastimate_app/services/auth_service.dart';
import 'package:procastimate_app/mainapp/settings_screen.dart';
import 'package:procastimate_app/mainapp/calendar_screen.dart';
import 'package:procastimate_app/mainapp/score_screen.dart';
import 'package:procastimate_app/mainapp/profile_screen.dart';
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
  String _username = ''; // ✅ Unified to match all references
  String? _photoUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initUserAndTasks();
  }

  Future<void> _initUserAndTasks() async {
    await _loadUserName();
    await loadTasks();
    setState(() => _loading = false);
  }

  /// ✅ Safe username loader
  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _username = data?['username'] ??
              user.displayName ??
              user.email?.split('@').first ??
              'User';
          _photoUrl = data?['photoUrl'];
        });
      } else {
        setState(() {
          _username = user.displayName ?? user.email?.split('@').first ?? 'User';
        });
      }
    } catch (e) {
      debugPrint('Error loading username: $e');
      setState(() {
        _username = user.displayName ?? user.email?.split('@').first ?? 'User';
      });
    }
  }

  Future<void> saveTasks() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final Map<String, dynamic> taskMap = tasksByDate.map(
      (key, tasks) => MapEntry(key, tasks.map((t) => t.toJson()).toList()),
    );

    try {
      await userDoc.set({'tasksByDate': taskMap}, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tasks saved to cloud.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save tasks: $e')),
      );
    }
  }

  Future<void> loadTasks() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()?['tasksByDate'] != null) {
        final Map<String, dynamic> decoded =
            Map<String, dynamic>.from(doc.data()!['tasksByDate']);
        setState(() {
          tasksByDate.clear();
          decoded.forEach((key, list) {
            tasksByDate[key] =
                (list as List).map((t) => Task.fromJson(t)).toList();
          });
        });
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
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

  void _openCreateTaskDialogForDate(String dateKey) =>
      _openTaskDialog(existingDate: dateKey);

  void _openCreateTaskDialog() => _openTaskDialog();

  void _openTaskDialog({String? existingDate}) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? dueDate =
        existingDate != null ? DateTime.tryParse(existingDate) : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDateTime() async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: dueDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(
                      dueDate ?? DateTime.now().add(const Duration(hours: 1))),
                );
                final finalTime =
                    pickedTime ?? const TimeOfDay(hour: 0, minute: 0);
                setDialogState(() {
                  dueDate = DateTime(pickedDate.year, pickedDate.month,
                      pickedDate.day, finalTime.hour, finalTime.minute);
                });
              }
            }

            return AlertDialog(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text("Create Task"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: "Title")),
                  TextField(
                      controller: descController,
                      decoration:
                          const InputDecoration(labelText: "Description")),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: Text(dueDate == null
                              ? "No due date"
                              : "Due: ${DateFormat('MM/dd/yyyy HH:mm').format(dueDate!)}")),
                      IconButton(
                          onPressed: pickDateTime,
                          icon: const Icon(Icons.calendar_today)),
                      if (dueDate != null)
                        IconButton(
                            onPressed: () => setDialogState(() => dueDate = null),
                            icon: const Icon(Icons.clear))
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel")),
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
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F3EF),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 72,
              color: Colors.brown.shade800,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProfileTab()),
                        );
                        _loadUserName();
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.white24,
                        backgroundImage:
                            _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                        radius: 18,
                        child: _photoUrl == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
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
                    IconButton(
                      icon: const Icon(Icons.settings,
                          color: Colors.white, size: 26),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 14),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Welcome, $_username!',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tasksByDate.isEmpty
                  ? const Center(
                      child: Text(
                        "No tasks yet.\nTap below to add one!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: tasksByDate.entries.map((entry) {
                          final dateKey = entry.key;
                          final tasks = entry.value;
                          final parsed =
                              DateTime.tryParse(dateKey) ?? DateTime.now();
                          final dateLabel =
                              DateFormat("MMMM d, yyyy").format(parsed);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _DateColumn(
                              dateLabel: dateLabel,
                              dateKey: dateKey,
                              tasks: tasks,
                              onToggleTask: (id) =>
                                  _toggleTaskCompletion(dateKey, id),
                              onDeleteTask: (id) => _deleteTask(dateKey, id),
                              onAddTask: (k) => _openCreateTaskDialogForDate(k),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'CREATE TASK',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[400],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: _openCreateTaskDialog,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          setState(() => _selectedIndex = i);
          if (i == 0) {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const CalendarScreen()));
          } else if (i == 2) {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ScoreScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Score'),
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
  final void Function(String taskId) onToggleTask;
  final void Function(String taskId) onDeleteTask;
  final void Function(String dateKey) onAddTask;

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
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Date + Add Task Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                  onPressed: () => onAddTask(dateKey),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Task List
            for (final task in tasks)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: task.completed
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: task.completed
                        ? Colors.green.shade300
                        : Colors.grey.shade300,
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Checkbox(
                    value: task.completed,
                    onChanged: (_) => onToggleTask(task.id),
                    activeColor: Colors.green.shade400,
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: task.completed
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.description != null &&
                          task.description!.isNotEmpty)
                        Text(task.description!,
                            style: const TextStyle(fontSize: 13)),
                      if (task.dueDate != null)
                        Text(
                          "Due: ${DateFormat('MM/dd HH:mm').format(task.dueDate!)}",
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => onDeleteTask(task.id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
