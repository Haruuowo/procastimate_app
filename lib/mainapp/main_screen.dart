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
import 'package:procastimate_app/models/task_data.dart'; // Assumed dependency
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  int _score = 0;

  // Streak state
  int _streakCount = 0;
  String? _lastStreakDate; // stored as 'yyyy-MM-dd'
  bool _streakActive = false;

  @override
  void initState() {
    super.initState();
    _initUserAndTasks();
  }

  Future<void> _initUserAndTasks() async {
    await _loadUserName();
    await loadTasks();
    await _loadScore();
    await _loadStreak(); // load streak state
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
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final Map<String, dynamic> taskMap = tasksByDate.map(
      (key, tasks) => MapEntry(key, tasks.map((t) => t.toJson()).toList()),
    );
    try {
      // Use update for the tasksByDate field so it replaces that field cleanly.
      await userDoc.update({'tasksByDate': taskMap});
    } catch (e) {
      // If update fails (e.g. document missing) fall back to set with merge
      try {
        await userDoc.set({'tasksByDate': taskMap}, SetOptions(merge: true));
      } catch (err) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save tasks: $err')));
      }
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
        final Map<String, dynamic> decoded = Map<String, dynamic>.from(
          doc.data()!['tasksByDate'],
        );
        setState(() {
          tasksByDate.clear();
          decoded.forEach((key, list) {
            tasksByDate[key] = (list as List)
                .map((t) => Task.fromJson(t))
                .toList();
          });
        });
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  Future<void> _loadScore() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      int firestoreScore = 0;
      if (doc.exists && doc.data()?['score'] != null) {
        firestoreScore = doc.data()!['score'] ?? 0;
      }
      setState(() {
        _score = firestoreScore;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('score', firestoreScore);
    } catch (e) {
      debugPrint('Error loading score: $e');
    }
  }

  Future<void> _saveScore(int score) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'score': score,
      }, SetOptions(merge: true));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('score', score);
    } catch (e) {
      debugPrint('Error saving score: $e');
    }
  }

  Future<void> _saveCompletedTask(Task task) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    try {
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      await userDoc.update({
        'completedTasks': FieldValue.arrayUnion([
          {
            'id': task.id,
            'title': task.title,
            'subject': task.subject,
            'description': task.description,
            'points': 5,
            'completedAt': DateTime.now().toIso8601String(),
            'dueDate': task.dueDate?.toIso8601String(),
          },
        ]),
      });

      // Save locally — insert at 0 so most recent is on top
      final prefs = await SharedPreferences.getInstance();
      final completedTasksRaw = prefs.getStringList('completedTasks') ?? [];
      completedTasksRaw.insert(
        0,
        jsonEncode({
          'id': task.id,
          'title': task.title,
          'subject': task.subject,
          'description': task.description,
          'points': 5,
          'completedAt': DateTime.now().toIso8601String(),
          'dueDate': task.dueDate?.toIso8601String(),
        }),
      );
      await prefs.setStringList('completedTasks', completedTasksRaw);
    } catch (e) {
      debugPrint('Error saving completed task: $e');
    }
  }

  // --- STREAK LOGIC ---
  // Streak rules:
  // - stored lastStreakDate as 'yyyy-MM-dd' local date
  // - if user completes >=1 task in a 24h window (ends at midnight local), streak continues
  // - if no completion within 24 hours (i.e. lastStreakDate older than yesterday), streak resets
  Future<void> _loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCount = prefs.getInt('streakCount');
    final savedDate = prefs.getString('lastStreakDate');

    // start with local prefs
    int localCount = savedCount ?? 0;
    String? localDate = savedDate;

    // try to get remote and prefer remote if present
    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            if (data['streakCount'] != null) {
              final rc = data['streakCount'];
              if (rc is int) {
                localCount = rc;
              } else if (rc is String)
                localCount = int.tryParse(rc) ?? localCount;
            }
            if (data['lastStreakDate'] != null) {
              localDate = data['lastStreakDate'];
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading streak from firestore: $e');
    }

    // compute if streak still valid
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal());
    final yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().toLocal().subtract(const Duration(days: 1)));

    if (localDate == today || localDate == yesterday) {
      // still active
      setState(() {
        _streakCount = localCount;
        _lastStreakDate = localDate;
        _streakActive = localCount > 0;
      });
    } else {
      // expired / reset
      setState(() {
        _streakCount = 0;
        _lastStreakDate = null;
        _streakActive = false;
      });
      // persist reset to both local prefs and firestore
      await _saveStreakToPrefsAndFirestore(0, null);
    }
  }

  Future<void> _saveStreakToPrefsAndFirestore(
    int count,
    String? lastDate,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('streakCount', count);
      if (lastDate != null) {
        await prefs.setString('lastStreakDate', lastDate);
      } else {
        await prefs.remove('lastStreakDate');
      }

      final user = AuthService.instance.currentUser;
      if (user != null) {
        final Map<String, dynamic> payload = {'streakCount': count};
        if (lastDate != null) {
          payload['lastStreakDate'] = lastDate;
        } else {
          payload['lastStreakDate'] = null;
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(payload, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving streak: $e');
    }
  }

  // Call when user completes a task
  Future<void> _updateStreakOnTaskCompletion() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal());
    final yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().toLocal().subtract(const Duration(days: 1)));

    if (_lastStreakDate == today) {
      // already counted today: nothing to change
      return;
    } else if (_lastStreakDate == yesterday) {
      // continue streak: increment
      _streakCount = (_streakCount >= 0) ? _streakCount + 1 : 1;
    } else {
      // streak broken or first time: start at 1
      _streakCount = 1;
    }

    _lastStreakDate = today;
    _streakActive = true;

    // persist
    await _saveStreakToPrefsAndFirestore(_streakCount, _lastStreakDate);
    setState(() {}); // refresh UI
  }

  // --- END STREAK LOGIC ---

  void _deleteTask(String dateKey, String taskId) {
    setState(() {
      final tasks = tasksByDate[dateKey];
      if (tasks == null) return;
      tasks.removeWhere((t) => t.id == taskId);
      if (tasks.isEmpty) tasksByDate.remove(dateKey);
    });
    saveTasks();
  }

  void _openTaskDialog({String? existingDate, Task? existingTask}) {
    final titleController = TextEditingController(
      text: existingTask?.title ?? '',
    );
    final subjectController = TextEditingController(
      text: existingTask?.subject ?? '',
    );
    final descController = TextEditingController(
      text: existingTask?.description ?? '',
    );
    DateTime? dueDate =
        existingTask?.dueDate ??
        (existingDate != null ? DateTime.tryParse(existingDate) : null);

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
                    dueDate ?? DateTime.now().add(const Duration(hours: 1)),
                  ),
                );
                final finalTime =
                    pickedTime ?? const TimeOfDay(hour: 0, minute: 0);

                setDialogState(() {
                  dueDate = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    finalTime.hour,
                    finalTime.minute,
                  );
                });
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  maxWidth: 400,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          existingTask == null ? "Create Task" : "Edit Task",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(labelText: "Title"),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: subjectController,
                          decoration: const InputDecoration(
                            labelText: "Subject",
                          ),
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
                                    : "Due: ${DateFormat('MMM d, yyyy').format(dueDate!)}",
                              ),
                            ),
                            IconButton(
                              onPressed: pickDateTime,
                              icon: const Icon(Icons.calendar_today),
                            ),
                            if (dueDate != null)
                              IconButton(
                                onPressed: () =>
                                    setDialogState(() => dueDate = null),
                                icon: const Icon(Icons.clear),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (existingTask != null)
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteTask(
                                    existingDate ??
                                        DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(existingTask.dueDate!),
                                    existingTask.id,
                                  );
                                },
                                child: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown.shade800,
                              ),
                              onPressed: () {
                                if (titleController.text.isNotEmpty &&
                                    subjectController.text.isNotEmpty) {
                                  final newTask = Task(
                                    id:
                                        existingTask?.id ??
                                        DateTime.now().millisecondsSinceEpoch
                                            .toString(),
                                    title: titleController.text,
                                    subject: subjectController.text,
                                    description: descController.text,
                                    dueDate: dueDate,
                                    completed: existingTask?.completed ?? false,
                                  );
                                  setState(() {
                                    if (existingTask != null) {
                                      final dateKey = DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(dueDate ?? DateTime.now());
                                      final list = tasksByDate[dateKey];
                                      if (list != null) {
                                        final index = list.indexWhere(
                                          (t) => t.id == existingTask.id,
                                        );
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
                              child: Text(
                                existingTask == null ? "Save" : "Save Changes",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openCreateTaskDialogForDate(String dateKey) {
    _openTaskDialog(existingDate: dateKey);
  }

  void _openCreateTaskDialog() {
    _openTaskDialog();
  }

  void _toggleTaskCompletion(String dateKey, String taskId) async {
    final tasks = tasksByDate[dateKey];
    if (tasks == null) return;
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    final task = tasks[index];
    final updated = task.copyWith(completed: true, completedAt: DateTime.now());

    // Update local state immediately so card vanishes.
    setState(() {
      _score += 5;
      tasks.removeAt(index);
      if (tasks.isEmpty) {
        tasksByDate.remove(dateKey);
      }
    });

    // Persist score and completed task, then persist updated tasksByDate to Firestore.
    await _saveScore(_score);
    await _saveCompletedTask(updated);
    await saveTasks();

    // Update streak when a task is completed
    await _updateStreakOnTaskCompletion();
  }

  void addTask(Task task) {
    final key = task.dueDate != null
        ? DateFormat('yyyy-MM-dd').format(task.dueDate!)
        : 'No due date';
    if (!tasksByDate.containsKey(key)) {
      tasksByDate[key] = [];
    }
    tasksByDate[key]!.add(task);
  }

  Widget _buildAvatarWithStreak() {
    // choose asset according to streak state
    final streakAsset = _streakActive
        ? 'assets/Streaks_On.png'
        : 'assets/Streaks_Off.png';

    // Use same visual size as profile avatar but avoid expanding the app bar.
    // Keep avatar radius matching other places (18 used elsewhere).
    const double avatarRadius = 18.0;
    final double avatarDiameter = avatarRadius * 2;

    return Row(
      children: [
        InkWell(
          onTap: () async {
            await Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileTab()));
            _loadUserName();
            await _loadStreak();
          },
          child: CircleAvatar(
            backgroundColor: Colors.white24,
            backgroundImage: _photoUrl != null
                ? NetworkImage(_photoUrl!)
                : null,
            radius: avatarRadius,
            child: _photoUrl == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        // streak badge (same size as avatar) - fixed box so it won't expand the app bar
        SizedBox(
          width: avatarDiameter,
          height: avatarDiameter,
          child: ClipOval(
            child: Image.asset(
              streakAsset,
              width: avatarDiameter,
              height: avatarDiameter,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) {
                return Container(
                  width: avatarDiameter,
                  height: avatarDiameter,
                  color: Colors.white24,
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        // only show the streak count (no label)
        Text(
          '$_streakCount',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
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
                // use Stack so title stays perfectly centered visually
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // left: avatar + streak
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildAvatarWithStreak(),
                    ),
                    // centered title
                    const Center(
                      child: Text(
                        "ProcrastiMate",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    // right: settings button
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
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
                          final dateLabel = DateFormat(
                            "MMM d, yyyy",
                          ).format(parsed);

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
                              onEditTask: (task) =>
                                  _openTaskDialog(existingTask: task),
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
                      borderRadius: BorderRadius.circular(28),
                    ),
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
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CalendarScreen()));
          } else if (i == 2) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ScoreScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
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
  final void Function(String taskId) onToggleTask;
  final void Function(String taskId) onDeleteTask;
  final void Function(String dateKey) onAddTask;
  final void Function(Task task) onEditTask;

  const _DateColumn({
    required this.dateLabel,
    required this.dateKey,
    required this.tasks,
    required this.onToggleTask,
    required this.onDeleteTask,
    required this.onAddTask,
    required this.onEditTask,
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
                    color: Colors.brown,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.green,
                  ),
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

  const _HoverableTaskCard({
    required this.task,
    required this.onToggle,
    required this.onTap,
  });

  @override
  State<_HoverableTaskCard> createState() => _HoverableTaskCardState();
}

class _HoverableTaskCardState extends State<_HoverableTaskCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isLate =
        widget.task.dueDate != null && widget.task.dueDate!.isBefore(now);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: widget.task.completed
                ? Colors.green.shade50
                : isLate
                ? Colors.red.shade50
                : (_hovering ? Colors.grey.shade200 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.task.completed
                  ? Colors.green.shade300
                  : isLate
                  ? Colors.red.shade300
                  : Colors.grey.shade300,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            leading: IconButton(
              icon: Icon(Icons.radio_button_unchecked, color: Colors.grey),
              onPressed: widget.onToggle,
              tooltip: "Mark as completed",
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (widget.task.subject != null)
                  Text(
                    widget.task.subject!,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                if (widget.task.dueDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "Due: ${DateFormat('MMM d, yyyy h:mm a').format(widget.task.dueDate!)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: isLate ? Colors.red : Colors.grey,
                        fontWeight: isLate
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
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
