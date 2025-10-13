// main_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String _username = '';
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
          _username =
              data?['username'] ??
              user.displayName ??
              user.email?.split('@').first ??
              'User';
          _photoUrl = data?['photoUrl'];
        });
      } else {
        setState(() {
          _username =
              user.displayName ?? user.email?.split('@').first ?? 'User';
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

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final Map<String, dynamic> taskMap = tasksByDate.map(
      (key, tasks) => MapEntry(key, tasks.map((t) => t.toJson()).toList()),
    );

    try {
      await userDoc.set({'tasksByDate': taskMap}, SetOptions(merge: true));
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
      if (tasks.isEmpty) tasksByDate.remove(dateKey);
    });
    saveTasks();
  }

  void _openCreateTaskDialogForDate(String dateKey) =>
      _openTaskDialog(existingDate: dateKey);

  void _openCreateTaskDialog() => _openTaskDialog();
void _openTaskDialog({String? existingDate, Task? existingTask}) {
  final titleController = TextEditingController(text: existingTask?.title ?? '');
  final subjectController = TextEditingController(text: existingTask?.subject ?? '');
  final descController = TextEditingController(text: existingTask?.description ?? '');
  DateTime? dueDate = existingTask?.dueDate ?? (existingDate != null ? DateTime.tryParse(existingDate) : null);

  showDialog(
    context: context,
    builder: (context) {
      return MediaQuery.removeViewInsets(   // 🛡 Prevent keyboard overflow
        context: context,
        removeBottom: true,
        child: StatefulBuilder(
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
                  initialTime: TimeOfDay.fromDateTime(dueDate ?? DateTime.now().add(const Duration(hours: 1))),
                );

                final finalTime = pickedTime ?? const TimeOfDay(hour: 0, minute: 0);

                setDialogState(() {
                  dueDate = DateTime(
                    pickedDate.year, pickedDate.month, pickedDate.day,
                    finalTime.hour, finalTime.minute,
                  );
                });
              }
            }

           return Dialog(
  insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: LayoutBuilder(
    builder: (context, constraints) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: constraints.maxHeight * 0.95, // Fit within screen
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                existingTask == null ? "Create Task" : "Edit Task",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: "Subject"),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: descController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Description",
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      dueDate == null
                          ? "No due date"
                          : "Due: ${DateFormat('MMM d, yyyy • h:mm a').format(dueDate!)}",
                    ),
                  ),
                  IconButton(
                    onPressed: pickDateTime,
                    icon: const Icon(Icons.calendar_today),
                  ),
                  if (dueDate != null)
                    IconButton(
                      onPressed: () => setDialogState(() => dueDate = null),
                      icon: const Icon(Icons.clear),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (existingTask != null)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteTask(
                          existingDate ??
                              DateFormat('yyyy-MM-dd')
                                  .format(existingTask.dueDate ?? DateTime.now()),
                          existingTask.id,
                        );
                      },
                      child: const Text("Delete", style: TextStyle(color: Colors.red)),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (titleController.text.isNotEmpty &&
                          subjectController.text.isNotEmpty) {
                        final newTask = Task(
                          id: existingTask?.id ??
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text,
                          subject: subjectController.text,
                          description: descController.text,
                          dueDate: dueDate,
                          completed: existingTask?.completed ?? false,
                        );

                        setState(() {
                          if (existingTask != null) {
                            final dateKey = DateFormat('yyyy-MM-dd')
                                .format(dueDate ?? DateTime.now());
                            final list = tasksByDate[dateKey];
                            if (list != null) {
                              final index = list.indexWhere((t) => t.id == existingTask.id);
                              if (index != -1) list[index] = newTask;
                            }
                          } else {
                            addTask(newTask);
                          }
                        });

                        saveTasks();
                        Navigator.pop(context);
                      }
                    },
                    child: Text(existingTask == null ? "Save" : "Save Changes"),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  ),
);

          },
        ),
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

  String _formatDueDateShort(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F3EF),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 🔽 Sort tasks chronologically by date key
    final sortedEntries = tasksByDate.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

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
                            MaterialPageRoute(
                                builder: (_) => const ProfileTab()));
                        _loadUserName();
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.white24,
                        backgroundImage: _photoUrl != null
                            ? NetworkImage(_photoUrl!)
                            : null,
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
                          fontSize: 20),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.settings,
                          color: Colors.white, size: 26),
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen())),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 14),
              child: Text(
                'Welcome, $_username 👋',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: tasksByDate.isEmpty
                  ? const Center(
                      child: Text(
                        "No tasks yet.\nTap below to add one!",
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : SingleChildScrollView(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: sortedEntries.map((entry) {
                          final dateKey = entry.key;
                          final tasks = entry.value;
                          final parsed = DateTime.tryParse(dateKey) ??
                              DateTime.now();
                          final dateLabel =
                              DateFormat("MMMM d, yyyy").format(parsed);
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: 16.0),
                            child: _DateColumn(
                              dateLabel: dateLabel,
                              dateKey: dateKey,
                              tasks: tasks,
                              onToggleTask: (id) =>
                                  _toggleTaskCompletion(dateKey, id),
                              onDeleteTask: (id) =>
                                  _deleteTask(dateKey, id),
                              onAddTask: (k) =>
                                  _openCreateTaskDialogForDate(k),
                              onEditTask: (task) =>
                                  _openTaskDialog(existingTask: task),
                              formatDue: _formatDueDateShort,
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
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
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
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CalendarScreen()));
          } else if (i == 2) {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ScoreScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
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
  final void Function(Task task) onEditTask;
  final String Function(DateTime) formatDue;

  const _DateColumn({
    required this.dateLabel,
    required this.dateKey,
    required this.tasks,
    required this.onToggleTask,
    required this.onDeleteTask,
    required this.onAddTask,
    required this.onEditTask,
    required this.formatDue,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: Colors.green),
                  onPressed: () => onAddTask(dateKey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final task in tasks)
              _HoverableTaskCard(
                task: task,
                onToggle: () => onToggleTask(task.id),
                onTap: () => onEditTask(task),
                formatDue: formatDue,
              ),
          ],
        ),
      ),
    );
  }
}

class _HoverableTaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final String Function(DateTime) formatDue;

  const _HoverableTaskCard({
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.formatDue,
  });

  @override
  State<_HoverableTaskCard> createState() => _HoverableTaskCardState();
}

class _HoverableTaskCardState extends State<_HoverableTaskCard> {
  bool _hovering = false;

  Color _dueTextColor() {
    if (widget.task.dueDate == null) return Colors.brown.shade400;
    final now = DateTime.now();
    final due = widget.task.dueDate!;
    if (widget.task.completed) return Colors.grey;
    if (due.isBefore(now)) return Colors.red;
    if (due.difference(now).inHours <= 24) return Colors.orange.shade700;
    return Colors.brown.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.task.completed;
    final titleStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: isCompleted ? Colors.grey.shade600 : Colors.black87,
      decoration:
          isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
    );

      final subjectStyle = TextStyle(
        fontSize: 13,
        color: isCompleted ? Colors.grey.shade500 : Colors.grey,
      );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: _hovering
                ? Colors.grey.shade200
                : (isCompleted ? Colors.green.shade50 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isCompleted ? Colors.green.shade300 : Colors.grey.shade300),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: Checkbox(
              value: isCompleted,
              onChanged: (_) => widget.onToggle(),
              activeColor: Colors.green.shade400,
            ),
            title: Text(widget.task.title, style: titleStyle),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.task.subject != null && widget.task.subject!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(widget.task.subject!, style: subjectStyle),
                  ),
                if (widget.task.dueDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      "Due: ${widget.formatDue(widget.task.dueDate!)}",
                      style: TextStyle(fontSize: 12, color: _dueTextColor(), fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
